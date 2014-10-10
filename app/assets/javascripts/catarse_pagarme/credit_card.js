App.views.PagarmeForm.addChild('PaymentCard', {
  el: '#payment_type_credit_card_section',

  events: {
    'keyup input[type="text"]' : 'creditCardInputValidator',
    'keyup #payment_card_number' : 'onKeyupPaymentCardNumber',
    'click input#credit_card_submit' : 'onSubmit',
    'change .creditcard-records' : 'onChangeCard'
  },

  onChangeCard: function(event){
    var $target = $(event.currentTarget);
    $target.siblings().removeClass('selected');
    $target.addClass('selected');
    if($(event.target).val() == 0){
      this.$('.type_card_data').slideDown('slow');
    }
    else{
      this.$('.type_card_data').slideUp('slow');
    }
  },

  activate: function(options){
    var that = this;
    this.pagarmeForm = this.parent;
    this.message = this.$('.payment-error-message');
    this.$('input#payment_card_date').mask('99/99');
  },

  getUrl: function(){
    var that = this;
    var url = '';

    if(that.$('input#payment_save_card').prop('checked') || that.hasSelectedSomeCard()) {
      url = '/payment/pagarme/'+that.parent.contributionId+'/pay_with_subscription';
    } else {
      url = '/payment/pagarme/'+that.parent.contributionId+'/pay_credit_card';
    }

    return url;
  },

  getAjaxType: function() {
    var type = 'POST';

    if(this.hasSelectedSomeCard()) {
      type = 'PUT'
    }
    return type;
  },

  selectedCard: function() {
    return this.$('input:radio[data-stored][name=payment_subscription_card]:checked');
  },

  hasSelectedSomeCard: function() {
    return this.selectedCard().length > 0;
  },

  getPaymentData: function() {
    var data = {};

    if(this.hasSelectedSomeCard()) {
      data = {
        subscription_id: this.selectedCard().val(),
        payment_card_installments: this.getInstallments() }
    } else {
      data = {
        payment_card_number: this.$('input#payment_card_number').val(),
        payment_card_name: this.$('input#payment_card_name').val(),
        payment_card_date: this.$('input#payment_card_date').val(),
        payment_card_source: this.$('input#payment_card_source').val(),
        payment_card_installments: this.getInstallments()
      }
    }

    return data;
  },

  getInstallments: function() {
    if(this.hasSelectedSomeCard()) {
      return this.$('.my-credit-cards .selected select#payment_card_installments').val();
    } else {
      return this.$('.type_card_data select#payment_card_installments').val();
    }
  },

  onSubmit: function(e) {
    var that = this;

    e.preventDefault();
    $(e.currentTarget).hide();
    that.parent.loader.show();

    $.ajax({
      type: that.getAjaxType(),
      url: that.getUrl(),
      data: that.getPaymentData(),
      success: function(response){
        that.parent.loader.hide();

        if(response.payment_status == 'failed'){
          that.message.find('.message-text').html(response.message);
          that.message.slideDown('slow')

          $(e.currentTarget).show();
        } else {
          var thank_you = $('#project_review').data('thank-you-path');

          if(thank_you){
            location.href = thank_you;
          } else {
            location.href = '/';
          }
        }
      }
    });
  },

  onKeyupPaymentCardNumber: function(e){
    this.$('#payment_card_flag').html(this.getCardFlag($(e.currentTarget).val()))
  },

  getCardFlag: function(number) {
    var cc = (number + '').replace(/\s/g, ''); //remove space

    if ((/^(34|37)/).test(cc) && cc.length == 15) {
      return 'AmericanExpress'; //AMEX begins with 34 or 37, and length is 15.
    } else if ((/^(51|52|53|54|55)/).test(cc) && cc.length == 16) {
      return 'Mastercard'; //MasterCard beigins with 51-55, and length is 16.
    } else if ((/^(4)/).test(cc) && (cc.length == 13 || cc.length == 16)) {
      return 'Visa'; //VISA begins with 4, and length is 13 or 16.
    } else if ((/^(300|301|302|303|304|305|36|38)/).test(cc) && cc.length == 14) {
      return 'Diners'; //Diners Club begins with 300-305 or 36 or 38, and length is 14.
    } else if ((/^(38)/).test(cc) && cc.length == 19) {
      return 'Hipercard';
    }
    return 'Desconhecido';
  }
});
