define = window?.define or (name, deps, cb) -> cb((require(dep.replace('cs!octokat-part/', './')) for dep in deps)...)
define 'octokat', [
  'cs!octokat-part/plus'
  'cs!octokat-part/grammar'
  'cs!octokat-part/chainer'
  'cs!octokat-part/replacer'
  'cs!octokat-part/request'
  'cs!octokat-part/helper-promise'
], (
  plus
  {TREE_OPTIONS, OBJECT_MATCHER}
  Chainer
  Replacer
  Request
  {toPromise}) ->

  # Combine all the classes into one client

  Octokat = (clientOptions={}) ->

    # For each request, convert the JSON into Objects
    _request = Request(clientOptions)

    request = (method, path, data, options={raw:false, isBase64:false, isBoolean:false}, cb) ->
      replacer = new Replacer(request)

      data = replacer.uncamelize(data) if data

      return _request method, path, data, options, (err, val) ->
        return cb(err) if err
        return cb(null, val) if options.raw

        obj = replacer.replace(val)
        url = obj.url or path
        for key, re of OBJECT_MATCHER
          if re.test(url)
            context = TREE_OPTIONS
            for k in key.split('.')
              context = context[k]
            Chainer(request, url, k, context, obj)
        return cb(null, obj)

    path = ''
    obj = {}
    Chainer(request, path, null, TREE_OPTIONS, obj)

    # Special case for `me`
    obj.me = obj.user
    delete obj.user

    # Add the GitHub Status API https://status.github.com/api
    obj.status =     toPromise (cb) -> request('GET', 'https://status.github.com/api/status.json', null, null, cb)
    obj.status.api = toPromise (cb) -> request('GET', 'https://status.github.com/api.json', null, null, cb)
    obj.status.lastMessage = toPromise (cb) -> request('GET', 'https://status.github.com/api/last-message.json', null, null, cb)
    obj.status.messages = toPromise (cb) -> request('GET', 'https://status.github.com/api/messages.json', null, null, cb)

    return obj


  module?.exports = Octokat
  window?.Octokat = Octokat
  return Octokat