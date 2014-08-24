class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def home

  end

  def world_github_standings
  	@most_commits = MostCommits.all.sort { |a, b| a.commits <=> b.commits }.reverse
  	@most_merged = MostMergedPulls.all.sort { |a, b| a.commits <=> b.commits }.reverse
  	@most_closed = MostClosedPulls.all.sort { |a, b| a.commits <=> b.commits }.reverse
  end

  def submit_github_username
  	begin
  		session["username"] = params["username"].downcase
  		body = JSON.parse(Nestful.get("https://api.github.com/users/#{session["username"]}?access_token=002496798f849c2b89d8341bc86e43c13b834e47",{:format => :json}).body)
  		redirect_to "/show_repositories"
  	rescue => e
  		puts e
  		flash[:error] = "User Not Found"
  		redirect_to "/"
  	end
  end

  def show_all_achievements
  	@achievements = Achievement.where(user: session["username"])
    @achievements = @achievements.group_by { |x| x["repository"] }
    @achievements = @achievements.collect { |k, v| [k, v.group_by { |y| y["achieved"].to_date }.sort { |a, b| a["achieved"] <=> b["achieved"] }.reverse.collect { |k1, k2| [k1, k2] }]}.sort { |x, y| x[0] <=> y[0] }
  end

  def show_repositories
  	@repos = JSON.parse(Nestful.get("https://api.github.com/users/#{session["username"]}/repos?access_token=002496798f849c2b89d8341bc86e43c13b834e47",{:format => :json}).body).collect { |repo| repo["name"] }.sort
  end

  def show_repo
  	@repo = params[:repo]
  	
  	@achievements = []

  	#largest # of commits

  	@num_of_commits = JSON.parse(Nestful.get("https://api.github.com/repos/#{session["username"]}/#{@repo}/commits?access_token=002496798f849c2b89d8341bc86e43c13b834e47",{:format => :json}).body)
  	if @num_of_commits.count != 0
  		@num_of_commits = @num_of_commits.collect { |x| x["committer"] != nil ? x["committer"]["login"] : nil }.group_by { |x| x }.collect { |k, v| [k, v.count] }
	  	@largest_commit_pos = 0
	  	i = 1
	  	@num_of_commits.each do |commit|
	  		if commit[0] != nil
		  		if commit[0].strip == session["username"].strip
		  			@largest_commit_pos = i
		  			m = MostCommits.where(user: session["username"])
		  			if m.count == 0
		  				m = MostCommits.new
		  				m.commits = commit[1].to_i
		  				m.user = session["username"]
		  				m.save!
		  			else
		  				m = m.first
		  				if commit[1].to_i > m.commits
		  					m.commits = commit[1].to_i
		  				end
		  				m.save!
		  			end
		  		end
		  	end
	  		i = i + 1
	  	end

	  	if @largest_commit_pos == 1
	  		@achievements << "Largest # of Commits"
	  	end
	end

  	#closed tickets

  	@closed_issues = JSON.parse(Nestful.get("https://api.github.com/repos/#{session["username"]}/#{@repo}/issues?access_token=002496798f849c2b89d8341bc86e43c13b834e47&state=closed",{:format => :json}).body)
  	if @closed_issues.count != 0
	  	@closed_issues = @closed_issues.group_by { |x| x["assignee"] == nil ? nil : x["assignee"]["login"] }.collect { |k, v| [k, v.count] }
	  	@my_closed_issues = @closed_issues.find { |x| x[0] == session["username"] }
		if @my_closed_issues != nil
			@my_closed_issues = @my_closed_issues[1].to_i
			m = MostClosedPulls.where(user: session["username"])
  			if m.count == 0
  				m = MostClosedPulls.new
  				m.pulls = @my_closed_issues
  				m.user = session["username"]
  				m.save!
  			else
  				m = m.first
  				if @my_closed_issues > m.commits
  					m.pulls = @my_closed_issues
  				end
  				m.save!
  			end
			puts @my_closed_issues
			if @my_closed_issues >= 1 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Stow Away (closed 1 Ticket)').count == 0
				@achievements << "Stow Away (closed 1 Ticket)"
			end
			if @my_closed_issues >= 5 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Cabin Boy (closed 5 Tickets)').count == 0
				@achievements << "Cabin Boy (closed 5 Tickets)"
			end
			if @my_closed_issues >= 10 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Oarsman (closed 10 Tickets)').count == 0
				@achievements << "Oarsman (closed 10 Tickets)"
			end
			if @my_closed_issues >= 25 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Deckhand (closed 25 Tickets)').count == 0
				@achievements << "Deckhand (closed 25 Tickets)"
			end
			if @my_closed_issues >= 50 && Achievement.where(user: session["username"], repository: @repo, achievement: 'First Mate (closed 50 Tickets)').count == 0
				@achievements << "First Mate (closed 50 Tickets)"
			end
			if @my_closed_issues >= 100 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Captain (closed 100 Tickets)').count == 0
				@achievements << "Captain (closed 100 Tickets)"
			end
			if @my_closed_issues >= 1000 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Admin (closed 1000 Tickets)').count == 0
				@achievements << "Admin (closed 1000 Tickets)"
			end
		end
	end

  	#merged pulls
  	@merged_issues = JSON.parse(Nestful.get("https://api.github.com/repos/#{session["username"]}/#{@repo}/pulls?access_token=002496798f849c2b89d8341bc86e43c13b834e47&state=closed",{:format => :json}).body)
  	if @merged_issues.count != 0
  		@merged_issues = @merged_issues.find { |x| x["merged_at"] != nil }.group_by { |x| x["user"] == nil ? nil : x["user"]["login"] }.collect { |k, v| [k, v.count] }
		@my_merged_issues = @merged_issues.find { |x| x[0] == session["username"] }
		if @my_merged_issues != nil
			@my_merged_issues = @my_merged_issues[1].to_i
			m = MostMergedPulls.where(user: session["username"])
  			if m.count == 0
  				m = MostMergedPulls.new
  				m.pulls = @my_merged_issues
  				m.user = session["username"]
  				m.save!
  			else
  				m = m.first
  				if @my_merged_issues > m.commits
  					m.pulls = @my_merged_issues
  				end
  				m.save!
  			end
			puts @my_merged_issues
			if @my_merged_issues >= 1 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Ignorant (1 Pull Approved)').count == 0
				@achievements << "Ignorant (1 Pull Approved)"
			end
			if @my_merged_issues >= 5 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Newbie (5 Pulls Approved)').count == 0
				@achievements << "Newbie (5 Pulls Approved)"
			end
			if @my_merged_issues >= 10 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Jockey (10 Pulls Approved)').count == 0
				@achievements << "Jockey (10 Pulls Approved)"
			end
			if @my_merged_issues >= 25 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Tech (25 Pulls Approved)').count == 0
				@achievements << "Deckhand (closed 25 Tickets)"
			end
			if @my_merged_issues >= 50 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Expert (50 Pulls Approved)').count == 0
				@achievements << "Tech (25 Pulls Approved)"
			end
			if @my_merged_issues >= 100 && Achievement.where(user: session["username"], repository: @repo, achievement: 'Master (100 Pulls Approved)').count == 0
				@achievements << "Master (100 Pulls Approved)"
			end
			if @my_merged_issues >= 1000 && Achievement.where(user: session["username"], repository: @repo, achievement: 'God (1000 Pulls Approved)').count == 0
				@achievements << "God (1000 Pulls Approved)"
			end
		end
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
  end

  def achievements
  	@repo = params[:repo]
  	@achievements = Achievement.where(user: session["username"], repository: @repo).sort { |x,y| x.achieved <=> y.achieved }.reverse.group_by { |a| a.achieved.to_date }
  end
end