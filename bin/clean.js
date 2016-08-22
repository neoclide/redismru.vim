var Parallel = require('node-parallel')
var redis = require('redis')
var fs = require('fs')
var path = require('path')

var client = redis.createClient(6379, '127.0.0.1')
client.on('error', function (err) {
  console.error('validate error: ' + err.message)
})

var key = 'vimmru'

client.zrange(key, 0, 4000, function (err, members) {
  var p = new Parallel()
  members.forEach(function (file) {
    p.add(function (cb) {
      fs.stat(file, function (err, stats) {
        if (err || !stats.isFile() || isTempFile(file)) {
          client.zrem(key, file, function (err) {
            if (err) return cb(err)
            cb()
          })
        } else {
          cb()
        }
      })
    })
  })
  p.done(function (err, results) {
    if (err) console.error('validate error: ' + err.message)
    client.quit()
    process.exit()
  })
})

function isTempFile(file) {
  var parts = file.split(/\//g)
  if (parts.indexOf('private') == 0) return true
  if (parts.indexOf('node_modules') !== -1) return true
  if (parts.indexOf('.git') !== -1) return true
  var base = path.basename(file)
  if (base.startsWith('.')) return true
  if (/bundle\.js/.test(base)) return true
  return false
}
