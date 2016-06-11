// async check mru files in redis
var redis = require('redis')
var attach = require('neovim-client')
var fs = require('fs')
var Parallel = require('node-parallel')
var socket = process.env.NVIM_LISTEN_ADDRESS
var net = require('net')

if (!socket) {
  console.error('NVIM_LISTEN_ADDRESS environment variable is required')
  process.exit()
}


var conn = net.connect({path: socket})
attach(conn, conn, function (err, nvim) {
  var variables = ['redismru_host', 'redismru_port', 'redismru_key']
  var parallel = new Parallel()
  variables.forEach(function (v) {
    parallel.add(function (cb) {
      nvim.eval('get(g:, "' + v + '", "")', function (err, val) {
        cb(err, val)
      })
    })
  })

  parallel.done(function (err, vals) {
    if (err) return console.error(err)
    var client = redis.createClient(vals[1] || 6379, vals[0] || '127.0.0.1')
    client.on('error', function (err) {
      console.error('validate error: ' + err.message)
    })
    var key = vals[2] || 'vimmru'

    client.zrange(key, 0, 4000, function (err, members) {
      var p = new Parallel()
      members.forEach(function (file) {
        p.add(function (cb) {
          fs.stat(file, function (err, stats) {
            if (err || !stats.isFile()) {
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
  })
})
