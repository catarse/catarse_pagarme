App.views.Pagarme.addChild('PaymentSlip', _.extend({
  el: '#payment_type_slip_section form',

  events: {
    'click input#build_boleto' : 'onBuildBoletoClick',
    'click .link_content a' : 'onContentClick',
    'blur input' : 'checkInput'
  },

  activate: function(options){
    app.userDocumentView.undelegateEvents();
    app._userDocumentView = null;
    app.userDocumentView;
    this.$('#user_bank_account_attributes_owner_name').data('custom-validation', this.validateName);

    this.setupForm();
    this.message = this.$('.payment-error-message');
    this.$('#user_bank_account_attributes_name').brbanks();
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

    if(!this.validate()){
      return false;
    }

    var parent = this.parent;

    e.preventDefault();
    $(e.currentTarget).hide();
    this.$('#payment-slip-instructions').slideUp('slow');
    that.parent.loader.show();

    $.post('/payment/pagarme/'+that.parent.contributionId+'/pay_slip.json',null, 'json').success(function(response){
      parent.loader.hide();
      if(response.payment_status == 'failed'){
        that.message.find('.message-text').html(response.message);
        that.message.slideDown('slow')

        $(e.currentTarget).show();
      } else if(response.boleto_url) {
        var link = $('<a class="alt-link" target="__blank">Clique aqui para ver o boleto e completar o pagamento.</a>')
        link.attr('href', response.boleto_url);
        that.$('.link_content').empty().html(link);
        that.$('> div:not(.after-success)').hide();
        that.$('#payment-slip-link').slideDown('slow');
      }
    });
  }

}, Skull.Form));
