http_request = (url, callback) ->

class Snapbill

    constructor: ->
        @object_cache = {}
        @base_url = "api.snapbill.com"

    request: (type, url, params, callback) ->
        params = Snapbill.encode_params params
        if typeof XMLHttpRequest != 'undefined'
            request = new XMLHttpRequest()
            request.onload = ->
                if request.readyState is 4
                    if 2 is Math.floor request.state / 100
                        callback JSON.parse request.responseText
                    else
                        @connectivity_error "Request to #{url} failed with request code #{request.status}"

            request.onerror = ->
                @connectivity_error "A network error occured"

            request.open type, base_url + url
            request.send params
        else
            http = require 'http'
            http_options =
                host: @base_url
                port: 80
                path: url
                method: type
                headers:
                    "content-type": "application/x-form-urlencoded"
                    "Accept": "application/json"
                    "Content-Length": params.length if params?
                auth: @username + ':' + @password

            req = http.request http_options, (res) =>
                result = ''
                res.on 'data', (data) ->
                    result += data
                res.on 'end', ->
                    console.log "Server result #{result}"
                    data = JSON.parse result
                    if data.code == 200
                        callback data, null
                    else
                        callback null, data

                if 2 isnt Math.floor res.statusCode
                    error_message = "Request to #{url} failed with error code #{res.statusCode}"
                    callback null, error_message
                    @connectivity_error error_message

            req.on 'error', (e) =>
                error_message "Request to #{url} failed. #{e.message}\nStack: #{e.stack}"
            req.write params
            req.end()



    @encode_params: (params) ->
        if typeof params is 'string'
            params
        else
            (k+"="+v for k, v of params).join('&')

    connectivity_error: (message) ->
        console.log "ERROR: #{message}"

class SnapbillObject
    constructor: (snapbill, objectData = {}) ->
        @snapbill = snapbill


    @create_object: (snapbill, type, objectData) ->
        cache = snapbill.object_cache
        typeName = type.type

        cache[typeName] = {} unless cache[typeName]?
        if not cache[typeName][objectData.id]?
            obj = new type.constructor snapbill, objectData

            for key, value of objectData
                if obj[key]? and obj[key] isnt value
                    throw new Error "Received data does not match existing values"
                if key isnt 'depth'
                    obj[key] = value

            cache[typeName][objectData.id] = obj

        return cache[typeName][objectData.id]

    @list: (snapbill, params, callback) ->
        snapbill.request "POST", "/v1/#{@type}/list", params, (requestData, error) =>
            if error?
                callback null, error
            else
                callback (SnapbillObject.create_object snapbill, this, objectData for objectData in requestData['list']), null


class User extends SnapbillObject
    @type: 'user'

    @login: (snapbill, username, password, loginCallback) ->
        snapbill.username = username
        snapbill.password = password

        User.list(snapbill, {
                "username": username,
                "password": password
            }, loginCallback)
        return

User.prototype.constructor = User
User.constructor = User

if exports?
    exports.User = User
    exports.Snapbill = Snapbill
    exports.SnapbillObject = SnapbillObject
