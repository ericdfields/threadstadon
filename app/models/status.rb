require 'net/http'
require 'json'

class Status < ApplicationRecord
  before_create :fetch_json_values
  after_create :fetch_replies

  has_many :statuses, foreign_key: "status_id"

  private

  def fetch_json_values

    if self.url && self.content.nil?
      # fetch the JSON data from the URL
      masto_domain = self.url.split('/')[2]
      masto_id = self.url.split('/')[4]
      uri = URI("https://#{masto_domain}/api/v1/statuses/#{masto_id}")
      response = Net::HTTP.get(uri)

      # parse the JSON data into a Ruby hash
      data = JSON.parse(response)

      # extract the values of id, url, content, published
      self.data = data
      self.foreign_id = data["id"]
      self.url = data["url"]
      self.content = data["content"]
      self.published = data["created_at"]

    end
    
  end

  def fetch_replies
    return if self.is_descendant

    # fetch the JSON data from the URL
    masto_domain = self.url.split('/')[2]
    masto_username = self.url.split('/')[3]
    masto_id = self.url.split('/')[4]
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
          data: descendant,
          foreign_id: descendant["id"], 
          url: descendant["url"], 
          content: descendant["content"], 
          published: descendant["created_at"], 
          status_id: self.id,
          is_descendant: true
        )
      end
    end
  end

  def reprocess
    self.fetch_json_values
    self.save
  end

end
