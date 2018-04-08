# Database Schema

## Author
Cam Cho, Alex Hu, Tom Willkens, Thomas Willkens, Zhengyang Zhou


## Users
- Id (primary key) : integer
- last name : String
- first name : String
- Username : String
- Email : String
- Password: String
- Password Digest: String
- Number_of_followers : integer
- Number_of_leaders: integer
- has_many users, through Follows
- has_many tweets
- has_many tweets, through Mentions


## Tweets
- Id (primary key): integer
- Message: String
- Tweeter (foreign key to user_id): integer
- Timestamp : date
- Foreign key (user_id) : integer
- Belongs_to users
- has_many users, through Mentions
- has_many Hashtags, through Hashtag_tweets


## Mentions (many-to-many between Users and Tweets)
- (foreign key) tweet_id: integer
- Username: string
- belongs_to Users
- belongs_to Tweets


## Follows (many to many between Users)
- (Foreign key)Follower(user_id): integer
- (Foreign key)Leader (user_id): integer
- belongs_to: Users


## Hashtag_tweets​ (many to many between tweets and hashtags)
- (Foreign key)Hashtag_id : integer
- (Foreign key)Tweet_id :integer
- belongs_to Hashtag
- belongs_to Tweets


## Hashtags
- Id (primary key) : integer
- Tag :string
- has_many Tweets, through Hashtag_tweets
