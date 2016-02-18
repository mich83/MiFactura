$(function(){
// IPad/IPhone
	var viewportmeta = document.querySelector && document.querySelector('meta[name="viewport"]'),
    ua = navigator.userAgent,
 
    gestureStart = function () {
        viewportmeta.content = "width=device-width, minimum-scale=0.25, maximum-scale=1.6";
    },
 
    scaleFix = function () {
      if (viewportmeta && /iPhone|iPad/.test(ua) && !/Opera Mini/.test(ua)) {
        viewportmeta.content = "width=device-width, minimum-scale=1.0, maximum-scale=1.0";
        document.addEventListener("gesturestart", gestureStart, false);
      }
    };
scaleFix();
// Menu Android
	var userag = navigator.userAgent.toLowerCase();
	var isAndroid = userag.indexOf("android") > -1; 
	if(isAndroid) {
		$('.sf-menu').responsiveMenu({autoArrows:true});
	}
	
	//	Initialize UItoTop
	//$().UItoTop({ easingType: 'easeOutQuart' });
	
	$('.soc-list li').hover(
		function(){
			$(this).find("img").stop().animate({opacity:'0.5'},200)
		},
		function(){
			$(this).find("img").stop().animate({opacity:'1'},200)
		}
	)
	$('.soc-list li').hover(
		function(){
			$(this).find("img").stop().animate({opacity:'0.5'},200)
		},
		function(){
			$(this).find("img").stop().animate({opacity:'1'},200)
		}
	)
	$('.block-1').hover(
		function(){
			$(this).find("img.absolute").stop().animate({opacity:'1'},200)
		},
		function(){
			$(this).find("img.absolute").stop().animate({opacity:'0'},200)
		}
	)
	$('.col-4').hover(
		function(){
			$(this).find("img").stop().animate({opacity:'0.5'},200)
		},
		function(){
			$(this).find("img").stop().animate({opacity:'1'},200)
		}
	)
	$('.block-1').hover(
		function(){
			$(this).find(".b-color-1").css({backgroundColor:'#f3c84b'})
		},
		function(){
			$(this).find(".b-color-1").css({backgroundColor:'#f1f1f1'})
		}
	)
	$('.block-1').hover(
		function(){
			$(this).find(".b-color-2").css({backgroundColor:'#5d8ee0'})
		},
		function(){
			$(this).find(".b-color-2").css({backgroundColor:'#f1f1f1'})
		}
	)
	$('.block-1').hover(
		function(){
			$(this).find(".b-color-3").css({backgroundColor:'#adde6a'})
		},
		function(){
			$(this).find(".b-color-3").css({backgroundColor:'#f1f1f1'})
		}
	)
	$('.block-1').hover(
		function(){
			$(this).find(".b-color-4").css({backgroundColor:'#9f9f9f'})
		},
		function(){
			$(this).find(".b-color-4").css({backgroundColor:'#f1f1f1'})
		}
	)
	$('.button').hover(
		function(){
			$(this).stop().animate({opacity:'0.5'},200)
		},
		function(){
			$(this).stop().animate({opacity:'1'},200)
		}
	)
});
