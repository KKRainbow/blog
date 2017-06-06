---
title: 为Hexo博客的代码片段添加 选择全部 按钮
date: 2017-06-06 17:07:36
tags: 
	- 技巧
	- Hexo
categories: 
	- Hexo
---

Hexo生成的博客中，代码片段是不支持选择全部功能的，若代码片段较长，手动选择非常的不方便。
添加的方法如下。
在页面模板文件（对于Next主题，模板文件为themes/next/layout/_layout.swig）的&lt;head&gt;节点中添加如下代码。

```javascript
$(document).ready(function () {
	var SelectText = function(element) {
		var doc = document
			, text = element
			, range, selection
		;    
		if (doc.body.createTextRange) {
			range = document.body.createTextRange();
			range.moveToElementText(text);
			range.select();
		} else if (window.getSelection) {
			selection = window.getSelection();        
			range = document.createRange();
			range.selectNodeContents(text);
			selection.removeAllRanges();
			selection.addRange(range);
		}
	};

	$(".code").each(function() {
		var code = $(this).get(0);
		var button_html = 
			'<div style="position: fixed;'                                                               +
						'right: 3%;'                                                                     +
						'margin-top: 5px;'                                                               +
						'font-family: consolas, Menlo, \'PingFang SC\', \'Microsoft YaHei\', monospace;' +
						'font-size: 10px;'                                                                +
						'cursor: pointer;'                                                               +
						'color: #e31436;'                                                                +
						'">'                                                                             +
			'<span>全选</span>'                                                                            +
			'</div>';
		var button = $(button_html);

		$(button).click(function() {
			SelectText(code);
		});
		$(button).insertBefore(this);
	});
});
```

