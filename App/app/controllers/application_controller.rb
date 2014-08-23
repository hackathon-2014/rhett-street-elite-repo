class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def home

  end

  def submit_github_username
  	begin
  		session["username"] = params["username"]
  		body = JSON.parse(Nestful.get("https://api.github.com/users/#{session["username"]}?access_token=002496798f849c2b89d8341bc86e43c13b834e47",{:format => :json}).body)
  		session["name"] = body["name"]
  		redirect_to "/show_repositories"
  	rescue => e
  		puts e
  		flash[:error] = "User Not Found"
  		redirect_to "/"
  	end
  end

  def show_repositories
  	@repos = JSON.parse(Nestful.get("https://api.github.com/users/#{session["username"]}/repos?access_token=002496798f849c2b89d8341bc86e43c13b834e47",{:format => :json}).body).collect { |repo| repo["name"] }.sort
  end

  def show_repo
  	@repo = params[:repo]
  	`git clone https://github.com/#{session["username"]}/#{@repo}.git`

  	@commits = `git -C #{@repo} shortlog -sn`.scan(/(\d+)\s(.+)/).sort { |x, y| x[0].to_i <=> y[0].to_i }.reverse
  	@commit_pos = 0
  	i = 1
  	@commits.each do |commit|
  		puts commit[1]
  		if commit[1].strip == session["name"].strip
  			@commit_pos = i
  		end
  		i = i + 1
  	end

  	`rm -rf #{@repo}`
  end
end