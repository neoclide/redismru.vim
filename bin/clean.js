var Parallel = require('node-parallel')
var redis = require('redis')
var fs = require('fs')
var path = require('path')
var oneYearAgo = Math.floor(Date.now()/1000) - 24*60*60*365

var client = redis.createClient(process.argv[3], process.argv[2])
client.on('error', function (err) {
  console.error('validate error: ' + err.message)
})

var key = process.argv[4] || 'vimmru'

client.zrange(key, 0, 8000, function (err, members) {
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
          client.zscore(key, file, function (err, score) {
            if (err) return cb(err)
            if (score < oneYearAgo) {
              client.zrem(key, file, cb)
            } else {
              cb()
            }
          })
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
  if (parts.indexOf('tmp') == 0) return true
  if (parts.indexOf('private') == 0) return true
  if (parts.indexOf('node_modules') !== -1) return true
  if (parts.indexOf('.git') !== -1) return true
  var base = path.basename(file)
  if (base.startsWith('.')) return true
  if (/bundle\.js/.test(base)) return true
  return false
}
