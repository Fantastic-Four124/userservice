require 'json'

payload = Hash.new
payload["keys"] = ["username","password","email"]
payload["values"] = []
for i in 3..1000
  sub = [i.to_s,i.to_s,i.to_s]
  payload["values"] << sub
end
File.open("public/payload.json","w") do |f|
  f.write(payload.to_json)
end

payload_login = Hash.new
payload_login["keys"] = ["username","password"]
payload_login["values"] = []
for i in 3..1000
  sub = [i.to_s,i.to_s]
  payload_login["values"] << sub
end
File.open("public/payload_login.json","w") do |f|
  f.write(payload_login.to_json)
end
