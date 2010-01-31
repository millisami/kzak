class PostsController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :get_filename, :get_audio_info, :only => :create

  def index
    @feed_items = current_user.feed_items.all :include => {:post => :user}
    # TODO followings/followers ordering not working (using sort_by in the view)
    @followings = current_user.followings :include => :user
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build :attachment => params[:Filedata], :title => @title, :artist => @artist, :album => @album
    @post.save!
    render :partial => @post
  rescue => e
    notify_hoptoad(e) if CONFIG['hoptoad_key'].present?
    render :partial => 'error', :locals => {:filename => @filename}
  end

  # def destroy
  #   @post = current_user.posts.find(params[:id])
  #   @post.destroy
  #   redirect_to root_path
  # end

  protected

  def get_filename
    @filename ||= params[:Filedata].original_filename rescue nil # for posts/new form
  end

  def get_audio_info
    if @filename =~ /.mp3$/
      Mp3Info.open(params[:Filedata].path) do |r|
        @title = r.tag.title
        @artist = r.tag.artist
        @album = r.tag.album
      end
    elsif @filename =~ /.mp4$|.m4a$/
      info = MP4Info.open(params[:Filedata].path)
      @title = info.send(:NAM)
      @artist = info.send(:ART)
      @album = info.send(:ALB)
    end
    @title = @title.toutf8 rescue 'Unknown'
    @artist = @artist.toutf8 rescue 'Unknown'
    @album = @album.toutf8 rescue 'Unknown'
  end
end