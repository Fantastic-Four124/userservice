# FantasticFour API design
* Author: Cam Cho, Alex Hu, Tom Willkens, Zhengyang Zhou

++++
###### For Users

* POST api/v1/register/users/{:id}              
//Create a new user with id [:id]

* PUT api/v1/users/{:id}                        
//Update the profile of user[:id]

* GET api/v1/users/{:id}                        
//Gets profile page of user[:id], will feature the user's 50 most recent Tweets

* GET api/v1/users/{:id}/followers              
//Gets a list of the users following user[:id]

* PUT api/v1/users/{:id}/follow/{leader_id}     
//Updates the list of user[:id]'s leaders by adding a leader

* DELETE api/v1/users/{:id}/unfollow/{leader_id}    
//Updates the list of user[:id]'s leaders by removing a leader

* GET api/v1/users/{:id}/leaders                
//Gets a list of the users user[:id] is following

* POST api/v1/users/{:id}/tweets/new            
//Creates a Tweet posted by user[:id]

++++(edited)
++++


###### General

* GET api/v1/home/{:session_id=null}            
//Fetches the home page and the 50 most recent Tweets posted to the database

* GET api/v1/home/{:session_id={:id}}          
 //Fetches the home page and the 50 most recent Tweets posted by user[:id]'s leaders

* GET api/v1/login                              
//Directs user to the login page

* GET api/v1/login/{:id}/{:password_hash}       
//User attempts to login. Will redirect to /login if it failed, and /home/{session_id={:id}} if it succeeded

* GET api/v1/register                           
//Directs user to the registration page

* GET api/v1/search                             
//Fetches the search page

* GET api/v1/search/{:search_terms}/results     
//Fetches the Tweets or users based on provided search terms

++++(edited)
++++


###### Hashtags

* GET api/v1/hashtags/{:term}                   
//Gets a list of Tweets with that particular Hashtag

++++
