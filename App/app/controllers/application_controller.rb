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

  	@achievements = []

  	@num_of_commits = `git -C #{@repo} shortlog -sn`.scan(/(\d+)\s(.+)/).sort { |x, y| x[0].to_i <=> y[0].to_i }.reverse
  	@largest_commit_pos = 0
  	i = 1
  	@num_of_commits.each do |commit|
  		puts commit[1]
  		if commit[1].strip == session["name"].strip
  			@largest_commit_pos = i
  		end
  		i = i + 1
  	end

  	if @largest_commit_pos == 1
  		@achievements << "Largest # of Commits"
  	end

  	@achievements.each do |achievement|
  		found = false
  		Achievement.where(user: session["username"], repository: @repo, achievement: achievement).each do |record|
  			if record.achieved.to_date == Date.today
  				found = true
  			end
  		end

  		if !found
  			a = Achievement.new
  			a.user = session["username"]
  			a.repository = @repo
  			a.achievement = achievement
  			a.achieved = Time.now
  			a.save!
  		end
  	end

  	`rm -rf #{@repo}`
  end

  def achievements
  	@repo = params[:repo]
  	@achievements = Achievement.where(user: session["username"], repository: @repo).sort { |x,y| x.achieved <=> y.achieved }.reverse.group_by { |a| a.achieved.to_date }
  end
end