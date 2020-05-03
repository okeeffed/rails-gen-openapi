# Converting a rails routes output into a Postman Collection

In an effort to learn a little bit about Ruby and Rails, I decided a fun project would be to attempt generating a YAML file that aligns to the OpenAPI v3.0 specification that I could import into Postman and test routes without manually having to do things via the Rails console and/or the consuming frontend application.

As this relates to what could be important information, I am going to redact as much as possible.

For context - I am normally writing in JS, Python, Swift, Rust (if I don't need C) or Golang these days. I knew jack shit about Ruby coming into this (other than general basics).

## tl;dr to run

```shell
bundle install
# Expects you to have a routes.txt file at the root in the expect format.
# See "Converting it down to a more consumable format" for more info.
# The file was git ignored as I felt it "could" be considered protected info.
./bin/run.sh
```

## Aims + Outcomes

What I wanted to achieve:

1. Understanding more about Rails in general.
2. Understanding a number of Ruby Gems: namely `dry-rb` gems, `rake`, `rspec` and `factory-bot` (the latter two which I ran out of time for).
3. Learning about file systems for the Ruby ecosystem - the most important aspect of any language.
4. Learning how to write CLIs in Ruby and sussing out the gems.
5. Just learning Ruby in general. I don't know huge amounts other than the usual suspects and reading docs when I need answers.

## Shortcuts taken

Initially I wanted to take the output of `rails routes` and manipulate it from there, but for the sake of time I cut it back.

At first, I also wanted to resolve all the controller functions and generate a placeholder for the final important request body to Postman, but I soon realised this wouldn't be so feasible with the file structure and changing approach to code.

## Getting started

To get my head around Rails, I did the following:

1. A one-over of the Rails API my team uses to see what does/doesn't make sense.
2. Reading the Ruby and Rails docs on Dash (surprisingly a good idea).
3. Checking out the Rails source code.
4. Bought and read "Active Rails" (skimmed over after the first few chapters on migrations).

## Converting it down to a more consumable format

I made a decision on what I considered the important parts of the application. I took the initial output that I would get from `rails routes` and did some manual cleansing.

The initial output looked like so (what a mess with the whitespace, I know):

```text
                                                                              Prefix Verb     URI Pattern                                                                                                                           Controller#Action
                                                                              roboto          /robots.txt                                                                                                                           Roboto::Engine
                                                                                root GET      /                                                                                                                                     home#show
                                                          native_oauth_authorization GET      /path/to/authorize/native(.:format)                                                                                                     doorkeeper/authorizations#show
                                                                 oauth_authorization GET      /path/to/authorize(.:format)                                                                                                            doorkeeper/authorizations#new
                                                                                     DELETE   /path/to/authorize(.:format)                                                                                                            doorkeeper/authorizations#destroy
                                                                                     POST     /path/to/authorize(.:format)                                                                                                            doorkeeper/authorizations#create
```

While I could have written the code to cleanse this back, I decided to do some manual culling.

First, I echo the routes into a file to work with ie `bin/rails routes > routes.txt`.

Next, I identified that `Verb`, `URI Pattern` and `Controller#Action` as the pieces of information I wanted, so I ended up using some regex cleaning in VSCode (use whatever) using `.+?(?=GET|DELETE|POST|PUT|PATCH)` to replace with `''` to trim the start and manually cut out the few lines left that were not aligned to the format I wanted (first line, three others related to GraphQL that I could manually add once to Postman anyways).

```text
GET      /                          home#show
GET      /path/to/authorize/native     doorkeeper/authorizations#show
GET      /path/to/authorize            doorkeeper/authorizations#new
DELETE   /path/to/authorize            doorkeeper/authorizations#destroy
POST     /path/to/authorize            doorkeeper/authorizations#create
# so on and so forth for all 900+ routes
```

## Writing the base CLI tool

I did what I always do here and went to `awesome` [GitHub repo for the language](https://github.com/markets/awesome-ruby) and looked at the suggested CLI libraries. I just went with `Slop` as it seemed super basic. There were a few good options.

I generated the `main.rb` file as the app entrypoint and legit only use `Slop` to parse for `-f` or `--file` for a path the `routes.txt` file.

## The workflow with the Result monads

After that, the application itself is basically to call a file helper to parse the file and get it into an array of `RouteInfo` structs and then a second phase to take that array and mold is to the `OpenAPI` specification.

The file helper part is quite straight forward. I rescued any errors and propagated the error to identify where the methods would fail.

The OpenAPI helper was a little more complex because a) I stopped being so bothered and b) I was splitting up structs into smaller pieces. There are some helper methods there that I would prefer to be abstracted elsewhere but I wanted them as lambdas and it wasn't so straight forward for this Ruby n00b. I used a `deep_merge` Gem and I didn't really think through a nicer way to start immutable. This might not be a good decision.

Where possible, I used the `dry-types` and `dry-struct` libraries to learn how the worked and help with valiation of the classes. Unsure if I used these effectively, and I basically converted using the `attributes` method straight away but it was nice for catching type errors (which I really appreciated).

There are some comments prefixed with `# !` to indicate things that I was a bit unhappy with the decision, but are likely just the result of lack of real-world Ruby experience.

## The aftermath

I had an example OpenAPI v3 specification YAML file that I tried before writing all of this see how that worked when importing to Postman:

```yaml
openapi: 3.0.0
info:
  title: Sample API
  description: Optional multiline or single-line description in [CommonMark](http://commonmark.org/help/) or HTML.
  version: 0.1.9
servers:
  - url: http://api.example.com/v1
    description: Optional server description, e.g. Main (production) server
  - url: http://staging-api.example.com
    description: Optional server description, e.g. Internal staging server for testing
paths:
  /users:
    post:
      summary: Creates a new user.
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: string
  /users/{id}:
    get:
      summary: Gets a user.
    patch:
      summary: Gets a user.
```

This set as my basis for the structs and design of hashes and how I would write. The `success` lambda when folding at the end of the `main.rb` OpenAPI class monad did the conversion of symbols to strings and writing of the YAML file. The resulting file looked like so:

```yaml
openapi: 3.0.0
info:
  title: Culture Amp - Performance API
  description: Hotfix to add all routes to Postman
  version: 1.0.0
servers:
  url: http://localhost:7000
  description: Local dev environment
paths:
  '/':
    get:
      summary: home#show
  '/path/to/authorize/native':
    get:
      summary: doorkeeper/authorizations#show
  '/path/to/authorize':
    get:
      summary: doorkeeper/authorizations#new
    delete:
      summary: doorkeeper/authorizations#destroy
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: string
```

The above is omitting about 7000 lines. All 900+ route were successfully mapped. The initial home route did end up an empty string, so there is always work to do.

Because there was no easy way to find the models and copy their properties over, any REST verb other than `GET` just received a default JSON body of `id`. This means any call needs to be manually updated when using, but this is actually just so much better than nothing anyway.

## Importing to Postman

This part was the delightful part.

Once imported, you can `Generate Collection` on Postman and it would bring in all 900 requests.

[Add in photo of requests here]

After they were in, there was still two smaller pieces of work to be done. I had to update the default variables in Postman and set `{baseUrl}` to `http://localhost:7000` manually.

As for the requests made, I ended up jumping into the UI and watching the request information sent to the `API` when creating a team. I copied that info, found the correct request (Postman laid out the folders so nice!) and then BAM successfully managed to create a team from Postman.

[Add in success photos here]

> This is a great way to do some validation from outside of the Rails ecosystem while waiting on the UI to catch up.

While I didn't get to explore RSpec and the others, I considered this as mission success!

## Outstanding Questions

1. Can you go point-free for the `dry-rb` gems? Is using the `do notation` the preferred way? Can I compose without having to grab the return values from genetors and forwarding on the returned monad?
2. I didn't look too deep to see if Ruby supported reducers until right at the end, but I should have. That may have answered my question about if I used the identity monad. Still stands whether the `do notation` is the preferred way?
3. In general, can you define lambda funcs as Ruby class methods?
4. Still not fully around the diff between procs and lambdas other than procs returning from the parent scope on the return keyword (even that might be incorrect).
5. Are there issues when changing the database engines behind the DBMS you nominate for Rails? Thinking about the `ActiveModel` support for defining schemas.
6. Some of the `Result` monads I saw being used in the work controllers don't use an `either` method to fold the monad - wondering if there is a reason for raising HTTP errors instead of propagating a `Failure` monad and folding?
7. How does `hash.transform_keys(&:to_s)` work? I saw it as an option for converting hash keys but had no success, so I borrowed a dumb hack to extend the `Hash` class from Stack Overflow that I hate.
8. What's the best way to handle validation for large structs? Just flatten them? I had some deep nested holes growing.
9. I don't see many `rescue` blocks - is this an anti-pattern? A lot of `unless` etc so maybe all errors are handled inline?
10. What's the deal with splats? Tried doing one for a Struct constructor which didn't work but the following did in `irb` (maybe my misunderstanding between hashes and constructors?):

```ruby
irb(main):001:0> h = {"a": 3}
=> {:a=>3}
irb(main):002:0> a = {**h, "b": 4}
=> {:a=>3, :b=>4}
```

The post-mortem of this is that I at least got my feet wet with a lot of the different parts of Ruby and the gems we use. I am definitely up for any feedback anyone has on what is written as I am sure there were some anti-patterns here.
