require 'qiita'
require 'pry'
require 'fileutils'
require 'yaml'

ACCESS_TOKEN = ENV['QIITA_ACCESS_TOKEN']
TEAM_DOMAIN = ENV['QIITA_TEAM_DOMAIN']
ARTICLE_DIR = 'data/posts/'
META_DIR = 'data/meta/'
EXT = '.md'
META_EXT = '.yml'

class QiitaExporter
  def initialize(access_token, team_domain)
    @client = Qiita::Client.new(access_token: access_token, team: team_domain)
    @dir = ARTICLE_DIR
    @ext = EXT
    @meta_ext = META_EXT
    @meta_dir = META_DIR 
  end

  def export(page_num: 1, per_page: 10)
    FileUtils.mkdir_p(@dir)
    FileUtils.mkdir_p(@meta_dir)
    (1..page_num).each do |i|
      @client.list_items(page: i, per_page: per_page).body.each do |article|
        to_file(article)
      end
    end
  end

  private

  def to_file(article)
    meta = unravel(article)
    save_markdown(meta)
    save_meta(meta)
  end

  def save_meta(meta)
    formatted_meta = {
      meta[:id] => {
        'title' => meta[:title],
        'tags' => meta[:tags].map{|i| i["name"]},
        'user' => meta[:user],
        'created_at' => meta[:created_at]
      }
    }
    
    file_name = "#{@meta_dir}#{meta[:id]}#{@meta_ext}"
    FileUtils.touch(file_name) unless File.exist?(file_name)
    File.open(file_name, 'w') do |f|
      YAML.dump(formatted_meta, f)
    end
  end

  def save_markdown(meta)
    file_name = "#{@dir}#{meta[:id]}#{@ext}"
    FileUtils.touch(file_name) unless File.exist?(file_name)
    File.open(file_name, 'w').write(meta[:body])
  end

  def unravel(article)
    id = article['id']
    title = article['title']
    body = article['body']
    tags = article['tags']
    user = article['user']['id']
    user_image = article['user']['profile_image_url']
    created_at = article['created_at']
    {
     id: id,
     title: title,
     body: body,
     user: user, 
     user_image: user_image,
     tags: tags,
     created_at: created_at,
    }
  end

end

QiitaExporter.new(ACCESS_TOKEN, TEAM_DOMAIN).export
