/**
 * Equal Heights Plugin
 * Equalize the heights of elements. Great for columns or any elements
 * that need to be the same size (floats, etc).
 * 
 * Version 1.1
 * Updated 28/06/2010
 *
 * Copyright (c) 2008 Rob Glazebrook (cssnewbie.com) 
 *
 * Usage: $(object).equalHeights([minHeight], [maxHeight]);
 * 
 * Example 1: $(".cols").equalHeights(); Sets all columns to the same height.
 * Example 2: $(".cols").equalHeights(400); Sets all cols to at least 400px tall.
 * Example 3: $(".cols").equalHeights(100,300); Cols are at least 100 but no more
 * than 300 pixels tall. Elements with too much content will gain a scrollbar.
 * 
 */
(function(a){a.fn.equalHeights=function(c,b){tallest=c?c:0;this.each(function(){if(a.browser.msie&&a.browser.version.substr(0,1)<7){if(this.offsetHeight>tallest)tallest=this.offsetHeight}else if(a(this).height()>tallest)tallest=a(this).height()});if(b&&tallest>b)tallest=b;return this.each(function(){a.browser.msie&&a.browser.version.substr(0,1)<7?a(this).height(tallest):a(this).css({"*height":tallest,"min-height":tallest});$childElements=a(this).children(".autoPadDiv");$childElements.css({"*height":tallest, "min-height":tallest})})}})(jQuery);