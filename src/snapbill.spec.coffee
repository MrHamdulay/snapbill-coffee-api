(require 'better-require')()
snapbill = require './snapbill'

class MockSnapbillConnection extends snapbill.Snapbill
    constructor: ->
        super
        @responses = {}

    expectRequest: (url, jsonResponse) ->
        @responses[url] = jsonResponse

    request: (type, url, params, callback) ->
        callback @responses[url]
        delete @responses[url]

describe "Snapbill py api", ->
    it 'logs in to the api', ->
        snapbillMock = new MockSnapbillConnection
        snapbillMock.expectRequest '/v1/user/list', JSON.parse '
{ "code": 200,
  "type": "list",
  "page": 1,
  "numpages": 1,
  "class": "user",
  "list":
   [
     { "depth": 0,
       "id": 9541,
       "xid": "CaL:CVF",
       "username": "yaseen",
       "name": "Yaseen Hamdulay",
       "email": "yaseen@hamdulay.co.za",
       "type": "account",
       "client": null } ] }'

        snapbillMock = new snapbill.Snapbill
        users = null
        snapbill.User.login snapbillMock, 'yaseen', 'a', (u, error) =>
            expect(error).toBe(null)
            users = u
        waitsFor (=> users?) , "User should be received", 3000
        runs =>
            console.log users[0]
            expect(users[0].email).toBe('yaseen@hamdulay.co.za')
