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
  nvim.eval('get(g:, "redis_mru_key", "vimmru")', function (err, redis_key) {
    if (err) return console.error(err)
    var client = redis.createClient()
    client.on('error', function (err) {
      console.error('validate error: ' + err.message)
    })

    client.zrange(redis_key, 0, 2000, function (err, members) {
      var p = new Parallel()
      members.forEach(function (file) {
        p.add(function (cb) {
          fs.stat(file, function (err, stats) {
            if (err || !stats.isFile()) {
              client.zrem(redis_key, file, function (err) {
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
