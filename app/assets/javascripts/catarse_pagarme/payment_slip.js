App.views.PagarmeForm.addChild('PaymentSlip', {
  el: '#payment_type_slip_section',

  events: {
    'click input#build_boleto' : 'onBuildBoletoClick',
    'click .link_content a' : 'onContentClick',
  },

  activate: function(options){
    this.PagarmeForm = this.parent;
  },

  onContentClick: function() {
    var thank_you = $('#project_review').data('thank-you-path');

    if(thank_you){
      location.href = thank_you;
    } else {
      location.href = '/';
    }
  },

  onBuildBoletoClick: function(e){
    var that = this;
    var parent = this.parent;

    e.preventDefault();
    $(e.currentTarget).hide();
    that.PagarmeForm.loader.show();

    $.post('/payment/pagarme/'+that.PagarmeForm.contributionId+'/pay_slip').success(function(response){
      console.log(parent);
      parent.loader.hide();
      if(response.boleto_url) {
        var link = $('<a target="__blank">'+response.boleto_url+'</a>')
        link.attr('href', response.boleto_url);
        that.$('.link_content').empty().html(link);
        that.$('.payment_section:visible .subtitle').fadeIn('fast');
      }
    });
  }
});
