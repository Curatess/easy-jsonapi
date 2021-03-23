# frozen_string_literal: true

require 'rack/jsonapi/middleware'
require 'rack_app'
require 'oj'

describe JSONAPI::Middleware do

  # Middleware variables
  let(:m) { JSONAPI::Middleware.new(RackApp.new) }
  let(:m_user) do
    JSONAPI::Middleware.new(RackApp.new) do |config_manager|
      config_manager.global.required_document_members = { data: { attributes: { a1: nil } } }
    end
  end

  let(:body_str) do
    body_hash =
      {
        data: {
          type: 'articles',
          id: '1',
          attributes: {
            title: 'JSON:API paints my bikeshed!'
          },
          links: {
            self: 'http://example.com/articles/1'
          },
          relationships: {
            author: {
              links: {
                self: 'http://example.com/articles/1/relationships/author',
                related: 'http://example.com/articles/1/author'
              },
              data: { type: 'people', id: '9' }
            },
            comments: {
              links: {
                self: 'http://example.com/articles/1/relationships/comments',
                related: 'http://example.com/articles/1/comments'
              },
              data: [
                { type: 'comments', id: '5' },
                { type: 'comments', id: '12' }
              ]
            }
          }
        },
        included: [{
          type: 'people',
          id: '9',
          attributes: {
            'first-name': 'Dan',
            'last-name': 'Gebhardt',
            twitter: 'dgeb'
          },
          links: {
            self: 'http://example.com/people/9'
          }
        }, {
          type: 'comments',
          id: '5',
          attributes: {
            body: 'First!'
          },
          relationships: {
            author: {
              data: { type: 'people', id: '2' }
            }
          },
          links: {
            self: 'http://example.com/comments/5'
          }
        }, {
          type: 'comments',
          id: '12',
          attributes: {
            body: 'I like XML better'
          },
          relationships: {
            author: {
              data: { type: 'people', id: '9' }
            }
          },
          links: {
            self: 'http://example.com/comments/12'
          }
        }]
      }
    Oj.dump(body_hash)
  end

  let(:usr_body_str) do
    body_hash =
      {
        data: {
          type: 'articles',
          attributes: {
            title: 'JSON:API paints my bikeshed!'
          },
          links: {
            self: 'http://example.com/articles/1'
          },
          relationships: {
            author: {
              links: {
                self: 'http://example.com/articles/1/relationships/author',
                related: 'http://example.com/articles/1/author'
              },
              data: { type: 'people', id: '9' }
            },
            comments: {
              links: {
                self: 'http://example.com/articles/1/relationships/comments',
                related: 'http://example.com/articles/1/comments'
              },
              data: [
                { type: 'comments', id: '5' },
                { type: 'comments', id: '12' }
              ]
            }
          }
        }
      }
    Oj.dump(body_hash)
  end

  def env(body_str)
    {
      'SERVER_SOFTWARE' => 'thin 1.7.2 codename Bachmanity',
      'SERVER_NAME' => 'localhost',
      'rack.input' => StringIO.new(body_str),
      'rack.version' => [1, 0],
      'rack.multithread' => false,
      'rack.multiprocess' => false,
      'rack.run_once' => false,
      'REQUEST_METHOD' => 'POST',
      'REQUEST_PATH' => '/articles',
      'PATH_INFO' => '/articles',
      'QUERY_STRING' => 'include=author,comments&fields[articles]=title,body,author&fields[people]=name&josh_ua=demoss&page[offset]=1&page[limit]=1',
      'REQUEST_URI' => '/articles?include=author,comments&fields[articles]=title,body,author&fields[people]=name&josh_ua=demoss&page[offset]=1&page[limit]=1',
      'HTTP_VERSION' => 'HTTP/1.1', 
      'HTTP_ACCEPT' => 'application/vnd.api+json',
      'HTTP_HOST' => 'localhost:9292',
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'GATEWAY_INTERFACE' => 'CGI/1.2',
      'SERVER_PORT' => '9292',
      'SERVER_PROTOCOL' => 'HTTP/1.1',
      'rack.url_scheme' => 'http',
      'SCRIPT_NAME' => '',
      'REMOTE_ADDR' => '::1'
    }
  end

  
  # Create a document that includes data, but doesn't include a type
  let(:env_bad_doc) do
    bad_body_hash = {}
    bad_body_hash.replace Oj.load(body_str, symbol_key: true)
    bad_body_hash[:data].delete(:type)
    {
      'SERVER_SOFTWARE' => 'thin 1.7.2 codename Bachmanity',
      'SERVER_NAME' => 'localhost',
      'rack.input' => StringIO.new(Oj.dump(bad_body_hash)),
      'rack.version' => [1, 0],
      'rack.multithread' => false,
      'rack.multiprocess' => false,
      'rack.run_once' => false,
      'REQUEST_METHOD' => 'POST',
      'REQUEST_PATH' => '/articles',
      'PATH_INFO' => '/articles',
      'QUERY_STRING' => 'include=author,comments&fields[articles]=title,body,author&fields[people]=name&josh_ua=demoss&page[offset]=1&page[limit]=1',
      'REQUEST_URI' => '/articles?include=author,comments&fields[articles]=title,body,author&fields[people]=name&josh_ua=demoss&page[offset]=1&page[limit]=1',
      'HTTP_VERSION' => 'HTTP/1.1', 
      'HTTP_ACCEPT' => 'application/vnd.api+json',
      'HTTP_HOST' => 'localhost:9292',
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'GATEWAY_INTERFACE' => 'CGI/1.2',
      'SERVER_PORT' => '9292',
      'SERVER_PROTOCOL' => 'HTTP/1.1',
      'rack.url_scheme' => 'http',
      'SCRIPT_NAME' => '',
      'REMOTE_ADDR' => '::1'
    }
  end

  # Include a param with the name '***BAD_PARAM***'
  let(:env_bad_param) do
    {
      'SERVER_SOFTWARE' => 'thin 1.7.2 codename Bachmanity',
      'SERVER_NAME' => 'localhost',
      "rack.input" => StringIO.new(body_str),
      'rack.version' => [1, 0],
      'rack.multithread' => false,
      'rack.multiprocess' => false,
      'rack.run_once' => false,
      'REQUEST_METHOD' => 'POST',
      'REQUEST_PATH' => '/articles',
      'PATH_INFO' => '/articles',
      'QUERY_STRING' => 'include=author,comments&fields[articles]=title,body,author&fields[people]=name&bad=param&page[offset]=1&page[limit]=1',
      'REQUEST_URI' => '/articles?include=author,comments&fields[articles]=title,body,author&fields[people]=name&***BAD_PARAM***=demoss&page[offset]=1&page[limit]=1',
      'HTTP_VERSION' => 'HTTP/1.1', 
      'HTTP_ACCEPT' => 'application/vnd.api+json',
      'HTTP_POSTMAN_TOKEN' => 'de878a8f-917e-4016-b9f7-f723a6483f03',
      'HTTP_HOST' => 'localhost:9292',
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'GATEWAY_INTERFACE' => 'CGI/1.2',
      'SERVER_PORT' => '9292',
      'SERVER_PROTOCOL' => 'HTTP/1.1',
      'rack.url_scheme' => 'http',
      'SCRIPT_NAME' => '',
      'REMOTE_ADDR' => '::1'
    }
  end

  # Include a header with the 
  let(:env_bad_header) do
    {
      'SERVER_SOFTWARE' => 'thin 1.7.2 codename Bachmanity',
      'SERVER_NAME' => 'localhost',
      "rack.input" => StringIO.new(body_str),
      'rack.version' => [1, 0],
      'rack.multithread' => false,
      'rack.multiprocess' => false,
      'rack.run_once' => false,
      'REQUEST_METHOD' => 'POST',
      'REQUEST_PATH' => '/articles',
      'PATH_INFO' => '/articles',
      'QUERY_STRING' => 'include=author,comments&fields[articles]=title,body,author&fields[people]=name&page[offset]=1&page[limit]=1',
      'REQUEST_URI' => '/articles?include=author,comments&fields[articles]=title,body,author&fields[people]=name&josh_ua=demoss&page[offset]=1&page[limit]=1',
      'HTTP_VERSION' => 'HTTP/1.1', 
      'HTTP_ACCEPT' => 'application/vnd.api+json ; q=0.5, text/*, image/* ; q=.3',
      'HTTP_POSTMAN_TOKEN' => 'de878a8f-917e-4016-b9f7-f723a6483f03',
      'HTTP_HOST' => 'localhost:9292',
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'GATEWAY_INTERFACE' => 'CGI/1.2',
      'SERVER_PORT' => '9292',
      'SERVER_PROTOCOL' => 'HTTP/1.1',
      'rack.url_scheme' => 'http',
      'SCRIPT_NAME' => '',
      'REMOTE_ADDR' => '::1'
    }
  end

  let(:doc_error) { JSONAPI::Exceptions::DocumentExceptions::InvalidDocument }
  let(:user_doc_error) { JSONAPI::Exceptions::UserDefinedExceptions::InvalidDocument }
  let(:headers_error) { JSONAPI::Exceptions::HeadersExceptions::InvalidHeader }
  let(:query_params_error) { JSONAPI::Exceptions::QueryParamsExceptions::InvalidQueryParameter }

  let(:response) { [200, { "Content-Type" => "text/plain" }, ['Testing: JSONAPI::Request | JSONAPI::Document::Resource']] }

  describe '#call' do

    context 'when checking user defined exceptions' do
      it 'should return the appropriate response when a user configures the middleware to require certian document members' do
        expect { m_user.call(env(usr_body_str)) }.to raise_error user_doc_error
      end
    end

    it 'should return 503 without body message if env["MAINTENANCE] is set and in not in development' do
      e = env(body_str)
      e['MAINTENANCE'] = true
      expect(m.call(e)).to eq [503, {}, ['MAINTENANCE envirornment variable set']]
    end
    
    it 'should return 503 with message if env["MAINTENANCE] is not set or in development' do
      e = env(body_str)
      e['MAINTENANCE'] = true
      e['RACK_ENV'] = :production
      expect(m.call(e)).to eq [503, {}, []]
    end

    it 'should return the right response and instantiate a request object when data is included' do
      e = env(body_str)
      e['rack.input'].rewind

      resp = m.call(e)
      expect(resp).to eq response
    end

    context 'when part of the document does not follow the spec' do
      it 'should raise InvalidDocument if in development mode' do
        msg = 'The resource object (for a post request) MUST contain at least a type member'
        expect { m.call(env_bad_doc) }.to raise_error doc_error, msg
      end

      it 'should return a 400 level error otherwise' do
        env_bad_doc_production = {}
        env_bad_doc_production.replace env_bad_doc
        env_bad_doc_production['RACK_ENV'] = :production
        expect(m.call(env_bad_doc_production)).to eq [400, {}, []]
      end
    end

    context 'when a query param is invalid and it is a jsonapi request' do
      it 'should raise InvalidQueryParameter if in development mode' do
        msg = 
          'Implementation specific query parameters MUST adhere to the same constraints ' \
            'as member names. Allowed characters are: a-z, A-Z, 0-9 for beginning, middle, or end characters, ' \
            "and '_' is allowed for middle characters. (While the JSON:API spec also allows '-', it is not " \
            'recommended, and thus is prohibited in this implementation). ' \
            'Implementation specific query members MUST contain at least one non a-z character as well. ' \
            'Param name given: "bad"'
        expect { m.call(env_bad_param) }.to raise_error(query_params_error, msg)
      end

      it 'should return a 400 level error otherwise' do
        env_bad_param_production = {}
        env_bad_param_production.replace env_bad_param
        env_bad_param_production['RACK_ENV'] = :production
        expect(m.call(env_bad_param_production)).to eq [400, {}, []]
      end
    end

    context 'when a header is invalid and it is a jsonapi request' do
      it 'should raise InvalidHeader if in development mode' do
        msg = 'Clients that include the JSON:API media type in their Accept header MUST ' \
              'specify the media type there at least once without any media type parameters.'
        expect { m.call(env_bad_header) }.to raise_error headers_error, msg
      end

      it 'should return a 415 error for a Content-Type error' do
        env_bad_header_production = {}
        env_bad_header_production.replace env_bad_header
        env_bad_header_production["RACK_ENV"] = :production
        expect(m.call(env_bad_header_production)).to eq [406, {}, []]
      end
      
      it 'should return a 406 error if there is a Accept header error' do
        env_bad_header_production = {}
        env_bad_header_production.replace env_bad_header
        env_bad_header_production["RACK_ENV"] = :production
        env_bad_header_production["HTTP_ACCEPT"] = 'application/vnd.api+json'
        env_bad_header_production["CONTENT_TYPE"] = 'application/vnd.api+json; q=0.5'
        expect(m.call(env_bad_header_production)).to eq [415, {}, []]
      end
    end

    context 'when it recieves a GET request with a body' do
      it 'should raise runtime error' do
        get_env = {}
        get_env.replace(env(body_str))
        get_env['REQUEST_METHOD'] = 'GET'
        e_msg = 'GET requests cannot have a body.'
        expect { m.call(get_env) }.to raise_error headers_error, e_msg
      end
    end

    context 'when sending invalid json' do
      it 'should return a 400 level error if in production' do
        env_body_malformed = {}
        env_body_malformed.replace(env(body_str))
        env_body_malformed["RACK_ENV"] = :production
        env_body_malformed['rack.input'] = StringIO.new("[")
        expect(m.call(env_body_malformed)).to eq [400, {}, []]
      end
      
      it 'should raise if in development' do
        env_body_malformed = {}
        env_body_malformed.replace(env(body_str))
        env_body_malformed['rack.input'] = StringIO.new("[")
        expect { m.call(env_body_malformed) }.to raise_error Oj::ParseError
      end
    end
  end
end
