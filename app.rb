class App < Sinatra::Base
	enable :sessions
	set :server, 'thin'
	set :sockets, []
	get '/' do
		slim:index
	end


	post '/login' do
		db = SQLite3::Database.new("db/main.sqlite") 
		username = params["username"] 
		password = params["password"]
		accounts = db.execute("SELECT * FROM login WHERE username=?", username)
		account_password = BCrypt::Password.new(accounts[0][2])

		if account_password == password
			result = db.execute("SELECT id FROM login WHERE username=?", [username]) 
			session[:id] = accounts[0][0]
			session[:username] = accounts[0][1]
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
		if session[:login]
			slim(:login)
		else
			redirect("/error")
		end
	end

	get '/register' do
		slim(:register) 
	end

	post '/register' do
		db = SQLite3::Database.new('db/main.sqlite')
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
		session[:username] = nil
		redirect('/')
	end

	get '/signup_successful' do
		slim(:signup_successful)
	end

	get '/error' do
		slim(:error, locals:{msg:session[:message]})
	end
	
	get '/room/:id' do
		number = params[:id]
		if session[:login]
			db = SQLite3::Database.new("db/main.sqlite")
			if db.execute("SELECT users_history FROM Room WHERE users_history IS ?", session[:username]) == []
				db.execute("INSERT INTO Room ('users_history') VALUES(?)", session[:username])
				user_history = db.execute("SELECT users_history FROM Room")
				if !request.websocket?
					slim(:room, locals:{number:number, user_history:user_history})
				else
					request.websocket do |ws|
						ws.onopen do
							ws.send("Welcome to Room_#{number}")
							settings.sockets << ws
						end
						ws.onmessage do |msg|
							EM.next_tick do 			#+ Ta reda på vilket rum meddelandet ska skickas till.
								settings.sockets.each do |s|
									s.send(session[:username].to_s + ": " + msg) # Skickar detta till alla anslutna användare
								end
							end
						end
						ws.onclose do
							warn("Chatroom closed")
							settings.sockets.delete(ws)
						end
					end
				end
			else
				redirect("/error")
			end
		end
	end
end
#Vad har jag gjort?
#Vad var svårt/problem?
#Vad ska jag göra nästa gång? 
