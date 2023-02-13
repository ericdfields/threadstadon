require 'net/http'
require 'json'

class Status < ApplicationRecord
  has_prefix_id :stus, override_find: true, salt: "asdflkj"

  before_create :fetch_json_values, unless: :is_descendant

  has_many :statuses, foreign_key: "status_id"

  validates :url, presence: true
  validates :url, format: { with: URI.regexp }
  validates :url, format: { with: /http.*..*\/@.*\/\d*/ }

  private

  def fetch_json_values
    if self.url && self.content.nil?
      begin
        # fetch the JSON data from the URL
        Logger.new(STDOUT).info "Fetching parent"
        masto_domain = self.url.split('/')[2]
        masto_id = self.url.split('/')[4]
        uri = URI("https://#{masto_domain}/api/v1/statuses/#{masto_id}")
        response = Net::HTTP.get(uri)
        # parse the JSON data into a Ruby hash
        data = JSON.parse(response)

        if user_has_blocked(data)
          self.errors.add(:url, "URL cannot be indexed")
          throw(:abort)
        else
          # extract the values of id, url, content, published
          self.data = data
          self.foreign_id = data["id"]
          self.url = data["url"]
          self.content = data["content"]
          self.published = data["created_at"]
          self.save
          fetch_replies(self.url, self.id)
        end

      rescue JSON::ParserError => e
        # not sure if this even works
        self.errors.add(:url, "is not a Mastodon status URL")
      end
    end
  end

  def fetch_replies(url, status_id)
    # fetch the JSON data from the URL
    masto_domain = url.split('/')[2]
    masto_username = url.split('/')[3]
    masto_id = url.split('/')[4]
    uri = URI("https://#{masto_domain}/api/v1/statuses/#{masto_id}/context")
    response = Net::HTTP.get(uri)

    Logger.new(STDOUT).info "Fetching replies from #{uri}"

    # parse the JSON data into a Ruby hash
    data = JSON.parse(response)

    descendants = data["descendants"].each do |descendant|
      descendant_username = descendant["url"].split('/')[3]
      if descendant_username == masto_username
        Logger.new(STDOUT).info "Found reply: #{descendant["url"]}"
        Status.create(
          status_id: status_id,
          data: descendant,
          foreign_id: descendant["id"], 
          url: descendant["url"], 
          content: descendant["content"], 
          published: descendant["created_at"], 
          is_descendant: true
        )
      end
    end
  end

  def user_has_blocked(data)
    return true if data["account"]["noindex"]
    return true if /noindex|nobot|noarchive/i.match?(data["account"]["note"])
    return false
  end

  def reprocess
    self.fetch_json_values
    self.save
  end

end
