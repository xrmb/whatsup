$(function()
{
  if(document.login)
  {
    $('#login_popup').dialog();
    $(document.login).submit(function(e)
    {
      e.preventDefault();
      document.cookie = 'auth='+this.auth.value;
      location.reload();
    });
  }


  $('button').button();

  $('#topmenu .logout').click(function(e)
  {
    e.preventDefault();
    document.cookie = 'auth=; expires=Thu, 01 Jan 1970 00:00:00 UTC';
    location.reload();
  });

  $('tr.host').click(function()
  {
    var host = $(this).data('host');
    $('tr.app[data-host='+host+']').toggleClass('hidden');
  });

  $('tr.app').click(function()
  {
    var host = $(this).data('host');
    var app = $(this).data('app');
    $('tr.key[data-host='+host+'][data-app='+app+']').toggleClass('hidden');
  });
});
