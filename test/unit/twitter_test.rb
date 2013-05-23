# encoding: utf-8
require 'test_helper'
 
class TwitterTest < ActiveSupport::TestCase

  # app config
  consumer_key    = 'd2zoZBmMXmT7KLPgEHSzpw'
  consumer_secret = 'QMUrlyDlqjITCkWdrOgsTxMVVLxr4A4IW3DIgtIg'

  # user1: armin_theo (is system and is following marion_bauer)
  user1_token        = '1405469528-WQ6XHizgrbYasUwjp0I0TUONhftNkrfrpgFLrdc'
  user1_token_secret = '0LHChGFlQx9jSxM8tkBsuDOMhbJMSXTL2zKJJO5Xk'
  
  # user2: me_bauer (is following armin_theo)
  user2_token        = '1406098795-XQTjg1Zj5uVW0C11NNpNA4xopyclRJJoriWis0I'
  user2_token_secret = 'T8ph5afeSDjGDA9X1ZBlzEvoSiXfN266ZZUMj5UaY'

  # add channel
  current = Channel.where( :adapter => 'Twitter2' )
  current.each {|r|
    r.destroy
  }
  Channel.create(
    :adapter => 'Twitter2',
    :area    => 'Twitter::Inbound',
    :options => {
      :consumer_key       => consumer_key,
      :consumer_secret    => consumer_secret,
      :oauth_token        => user1_token,
      :oauth_token_secret => user1_token_secret,
      :search             => [
        {
          :item  => '#citheo42',
          :group => 'Twitter',
        },
        {
          :item  => '#citheo24',
          :group => 'Users',
        },
      ],
      :mentions => {
        :group => 'Twitter',
      },
      :direct_messages => {
        :group => 'Twitter',
      }
    },
    :active         => true,
    :created_by_id  => 1,
    :updated_by_id  => 1,
  )

  test 'new outbound and reply' do

    user  = User.find(2)
    group = Group.where( :name => 'Twitter' ).first
    state = Ticket::State.where( :name => 'new' ).first
    priority = Ticket::Priority.where( :name => '2 normal' ).first
    hash  = '#citheo42' + rand(9999).to_s
    text  = 'Today the weather is really nice... ' + hash
    ticket = Ticket.create(
      :group_id           => group.id,
      :customer_id        => user.id,
      :title              => text[0,40],
      :ticket_state_id    => state.id,
      :ticket_priority_id => priority.id,
      :updated_by_id      => 1,
      :created_by_id      => 1,
    )
    assert( ticket, "outbound ticket created" )
    article = Ticket::Article.create(
      :ticket_id                => ticket.id,
      :ticket_article_type_id   => Ticket::Article::Type.where( :name => 'twitter status' ).first.id,
      :ticket_article_sender_id => Ticket::Article::Sender.where( :name => 'Agent' ).first.id,
      :body                     => text,
#      :from                     => sender.name,
#      :to                       => to,
#      :message_id               => tweet.id,
      :internal                 => false,
      :updated_by_id            => 1,
      :created_by_id            => 1,
    )
    assert( article, "outbound article created" )
    assert_equal( article.ticket.articles.count, 1 )
    sleep 10

    # reply by me_bauer
    client = Twitter::Client.new(
      :consumer_key       => consumer_key,
      :consumer_secret    => consumer_secret,
      :oauth_token        => user2_token,
      :oauth_token_secret => user2_token_secret
    )
    tweets = client.search( hash )
    tweets.results.map do |tweet|
      assert_equal( tweet.id, article.message_id )
    end

    reply_hash = '#weather' + rand(9999).to_s
    reply_text = '@armin_theo on my side the weather is also nice! ' + reply_hash
    tweet = client.update(
      reply_text,
      {
        :in_reply_to_status_id => article.message_id
      }
    )

    sleep 10

    # fetch check system account
    Channel.fetch

    # check if follow up article has been created
    assert_equal( article.ticket.articles.count, 2 )
    reply_article = article.ticket.articles.last
    assert_equal( reply_article.body, reply_text )

  end

  test 'new by direct message inbound' do
    # cleanup direct messages of system
    client = Twitter::Client.new(
      :consumer_key       => consumer_key,
      :consumer_secret    => consumer_secret,
      :oauth_token        => user1_token,
      :oauth_token_secret => user1_token_secret
    )   
    dms = client.direct_messages( :count => 200 )
    dms.each {|dm|
      client.direct_message_destroy(dm.id)
    }

    # direct message to @armin_theo
    client = Twitter::Client.new(
      :consumer_key       => consumer_key,
      :consumer_secret    => consumer_secret,
      :oauth_token        => user2_token,
      :oauth_token_secret => user2_token_secret
    )
    dms = client.direct_messages( :count => 200 )
    dms.each {|dm|
      client.direct_message_destroy(dm.id)
    }
    sleep 5

    hash  = '#citheo44' + rand(9999).to_s
    text  = 'How about the details? ' + hash
    dm = client.direct_message_create(
      'armin_theo',
      text,
    )
    sleep 10

    # fetch check system account
    Channel.fetch

    # check if ticket and article has been created
    article = Ticket::Article.where( :message_id => dm.id ).last
    assert( article, "inbound article created" )
    ticket  = article.ticket
    assert( ticket, "ticket of inbound article exists" )
    assert( ticket.articles, "ticket.articles exists" )
    article_count = ticket.articles.count
    assert( article_count )
#    assert_equal( ticket.ticket_state.name, 'new' )

    # reply via ticket
    outbound_article = Ticket::Article.create(
      :ticket_id                => ticket.id,
      :ticket_article_type_id   => Ticket::Article::Type.where( :name => 'twitter direct-message' ).first.id,
      :ticket_article_sender_id => Ticket::Article::Sender.where( :name => 'Agent' ).first.id,
      :body                     => text,
#      :from                     => sender.name,
      :to                       => 'me_bauer',
      :internal                 => false,
      :updated_by_id            => 1,
      :created_by_id            => 1,
    )
    assert( outbound_article, "outbound article created" )
    assert_equal( outbound_article.ticket.articles.count, article_count + 1 )
    sleep 10

  end
end