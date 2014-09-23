App.views.PagarmeForm.addChild('PaymentCard', {
  el: '#payment_type_credit_card_section',

  events: {
    'keyup input[type="text"]' : 'creditCardInputValidator',
    'keyup #payment_card_number' : 'onKeyupPaymentCardNumber',
    'click input#credit_card_submit' : 'onSubmit',
    'click a.use_another-card': 'showCreditCardForm'
  },

  activate: function(options){
    var that = this;
    this.pagarmeForm = this.parent;
    this.$('input#payment_card_date').mask('99/99');
  },

  showCreditCardForm: function(e) {
    var that = this;
    e.preventDefault();

    that.$('ul.my_credit_cards').hide();
    that.$('a.use_another-card ').hide();
    that.$('.type_card_data').show();
    that.$('.save_card').show();

    $.each(that.$('.my_credit_cards input:radio[name=payment_subscription_card]'), function(i, item) {
      $(item).prop('checked', false);
    });
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
    return this.$('.my_credit_cards input:radio[name=payment_subscription_card]:checked');
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
      return this.$('.my_credit_cards select#payment_card_installments').val();
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
          that.parent.message.find('p').html(response.message);
          that.parent.message.fadeIn('fast')

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
    this.$('input#payment_card_flag').val(this.getCardFlag($(e.currentTarget).val()))
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
