/**
 * @Author: xiaoxiao
 * @Date: 2022-09-17 22:32:11
 * @LastEditTime: 2022-09-30 12:30:30
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\小爱测试\111.js
 * @QQ: 357914968
 */
var cheerio = require('cheerio'),
  $ = cheerio.load(`<ul id="fruits">
  <li class="apple">A:p?ple</li>
  <li class="orange">Orange</li>
  <li class="pear">Pear</li>
</ul>`)
$('ul > li').each(function () {
  console.log($(this).html())
})
