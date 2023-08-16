module.exports = {
  outputDir: '../bin/site',
  // publicPath 默认值为 '/'
  // 控制网页要部署到服务器的哪个路径下,  如果使用 ./ 相对路径,  那么网页能部署到任意路径下,  甚至能在文件管理器中直接打开网页
  // 但使用相对路径有两个限制, 参考 => https://cli.vuejs.org/config/#publicpath
  publicPath: '/',
  transpileDependencies: [
    'vuetify'
  ]
}
