class App < Sinatra::Base
	enable :sessions
	get '/' do
		slim:index
	end


	post '/login' do
		db = SQLite3::Database.new("main.sqlite") 
		username = params["username"] 
		password = params["password"]
		accounts = db.execute("SELECT * FROM login WHERE username=?", username)
		account_password = BCrypt::Password.new(accounts[0][2])

		if account_password == password
			result = db.execute("SELECT id FROM login WHERE username=?", [username]) 
			session[:id] = accounts[0][0] 
			session[:login] = true 
			redirect("/login")
		elsif password == nil
			redirect("/error")
		else
			session[:login] = false
		end
		redirect('/')
	end

	get'/login' do
		db = SQLite3::Database.new("main.sqlite") 
		rooms = db.execute("SELECT * FROM Room")
		slim(:login, locals:{rooms:rooms})
	end

	get '/register' do
		slim(:register) 
	end

	post '/register' do
		db = SQLite3::Database.new('main.sqlite')
		username = params["username"]
		password = params["password"]
		confirm = params["password2"]
		if confirm == password
			begin
				password_encrypted = BCrypt::Password.create(password)
				db.execute("INSERT INTO login('username' , 'password') VALUES(? , ?)", [username,password_encrypted])
				redirect('/signup_successful')

			 rescue 
			 	session[:message] = "Username is not available"
			 	redirect("/error")
			 end
		else
			session[:message] = "Password does not match"
			redirect("/error")
		end
	end

	post '/logout' do 
		session[:login] = false
		session[:id] = nil
		redirect('/')
	end

	get '/signup_successful' do
		slim(:signup_successful)
	end

	get '/error' do
		slim(:error, locals:{msg:session[:message]})
	end

	set :server, 'thin'
	set :sockets, []
	
	get '/room_1' do
	  if !request.websocket?
		slim(:room_1)
	  else
		request.websocket do |ws|
			ws.onopen do
			ws.send("Hello World!")
			settings.sockets << ws
		  end
		  ws.onmessage do |msg|
			EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
		  end
		  ws.onclose do
			warn("websocket closed")
			settings.sockets.delete(ws)
		  end
		end
	  end
	end

#Vad har jag gjort?
#Vad var svårt/problem?
#Vad ska jag göra nästa gång? 
	
	
	
end