
$('.js-main-menu .js-select-current-parent').first().addClass('selected')
$('.js-mobile-menu .js-select-current-parent').first().addClass('selected')
$('.js-submenu-make-visible').first().addClass('visible js-submenu-visible')
$('.js-submenu-make-visible > .js-select-current').first().addClass('selected')


$('.card-img').click((e)=>{
    $(e.currentTarget).parent().toggleClass('show')
})