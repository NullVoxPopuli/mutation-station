class Repository < ActiveRecord::Base
  belongs_to :user
  has_many :builds

  validates :name, :clone_url, presence: true

  WORKING_DIR = '/tmp'

  def github_repo
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)

    client.repo(name)
  end

  def working_directory
    cwd = File.join(WORKING_DIR, name)
    unless Dir.exist?(cwd)
      FileUtils.mkdir_p(cwd)

      Dir.chdir(cwd) do
        puts 'Cloning repository into...'
        response = `git clone #{clone_url} .`
        puts response
      end
    end

    cwd
  end

  def specs?
    spec_list.any?
  end

  def spec_list
    @spec_list = []

    filepath = working_directory
    if File.directory?(File.join(filepath, 'spec'))
      excluded_files = ['factories', 'rails_helper.rb', 'spec_helper.rb']
      @spec_list = Dir.glob(File.join(filepath, 'spec/**/*.rb')).reject do |x|
        excluded_files.any? { |f| x.include?(f) }
      end
    end

    @spec_list
  end

  def set_github_details
    gh = github_repo

    attributes = {
      clone_url: gh.clone_url,
    }

    assign_attributes(attributes)
  rescue Octokit::NotFound
    errors.add(:repository, 'cannot be located on GitHub.')
  end
end
