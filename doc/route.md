# Basic routing

## Author
Cam Cho, Alex Hu, Thomas Willkens, Zhengyang Zhou


# All routes start with “/api/v1”
## Home page (not logged in) (/)
Offer place to log-in (redirect to login page)
Offer place to register (redirect to register page)
Each tweet can link to the user that sent it, but the user must log in first
See a small list of tweets from all users

## Login page (/login)
If it is successful, redirect to home page (logged in).
Otherwise, go back to login page

## Login page (/logout)
Indicates that user has logged out

## Registration Page (/user/register)
If registration is passed, redirect to home page log-in
Otherwise, home-page non-logged in

## Home page (logged in) (/)
Log out link
See all tweets from people you’re following
Tweet box
Mini-profile that has a link to the user page


Each tweet can be linked to the user that sent it (your “leader,” in the diction of our application)

## User page (/user/:user_id)
Profile page and 50-odd tweets that user has made (including if you’re viewing your own page)
Each tweet has a link to the user that sent it
Button to follow that user (available only if logged in and not looking at self.)
Link to list of users followed by this user. Link text is a count.[leaders page]
Link to list of newest tweets of users followed by this user.[this user's timeline]
Link to list of users following this user. Link text is a count.[followers page]

## User leaders page (/user/:user_id/leaders)
See a list of the user’s leaders
Each entry can lead to that leader’s user page

## User followers page (/user/:user_id/followers)
See a list of the user’s followers
Each entry can lead to that follower’s user page

## User’s tweets (/user/:user_id/tweets)
Sees this user’s timeline

## Search page (/search)
Searching box for searching people or tweets

For other routes not mentioned, redirect to login page if user is not logged in
After sending out tweets, where should we redirect? (home page)
