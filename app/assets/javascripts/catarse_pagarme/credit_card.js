App.views.Pagarme.addChild('PaymentCard', _.extend({
  el: '#payment_type_credit_card_section form',

  events: {
    'keyup input[type="text"]' : 'creditCardInputValidator',
    'input #payment_card_number' : 'onKeyupPaymentCardNumber',
    'click input#credit_card_submit' : 'onSubmit',
    'change .creditcard-records' : 'onChangeCard',
    'blur input' : 'checkInput'
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
    this.setupForm();
    this.message = this.$('.payment-error-message');
    this.formatCreditCardInputs();
    window.app.maskAllElements();
  },

  formatCreditCardInputs: function(){
    this.$('#payment_card_number').payment('formatCardNumber');
    this.$('#payment_card_date').payment('formatCardExpiry');
    this.$('#payment_card_source').payment('formatCardCVC');
  },

  selectedCard: function() {
    return this.$('input:radio[data-stored][name=payment_subscription_card]:checked');
  },

  hasSelectedSomeCard: function() {
    return this.selectedCard().length > 0;
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

    if(!this.validate()){
      return false;
    }

    $(e.currentTarget).hide();
    that.parent.loader.show();

    if( that.hasSelectedSomeCard() ) {
      that.requestPayment({
        card_id: this.selectedCard().val(),
        payment_card_installments: that.getInstallments()
      });
    } else {
      PagarMe.encryption_key = this.$('.pagarme-e-key').data('key');

      var creditCard = this.newCreditCard();
      var fieldErrors = creditCard.fieldErrors();

      if(_.keys(fieldErrors).length > 0) {
        this.displayErrors(fieldErrors);
      } else {
        this.generateCardHash(creditCard);
      }
    }

    return false;
  },

  generateCardHash: function(creditCard){
    var that = this;
    creditCard.generateHash(function(cardHash) {
      that.requestPayment({
        card_hash: cardHash,
        payment_card_installments: that.getInstallments(),
        save_card: that.$('input#payment_save_card').is(':checked')
      });
    });
  },

  displayErrors: function(errors){
    var msg = [];
    this.parent.loader.hide();

    $.each(errors, function(i, value){
      msg.push(value)
    });

    this.message.find('.message-text').html(msg.join("<br/>"));
    this.message.slideDown('slow');

    $("#credit_card_submit").show();
  },

  newCreditCard: function(){
    var creditCard = new PagarMe.creditCard();
    creditCard.cardHolderName = this.$('input#payment_card_name').val();
    creditCard.cardExpirationMonth = $.trim(this.$('input#payment_card_date').val().split('/')[0]);
    creditCard.cardExpirationYear = $.trim(this.$('input#payment_card_date').val().split('/')[1]);
    creditCard.cardNumber = this.$('input#payment_card_number').val();
    creditCard.cardCVV = this.$('input#payment_card_source').val();
    return creditCard;
  },

  requestPayment: function(data){
    var that = this;

    $.ajax({
      type: 'POST',
      url: '/payment/pagarme/'+that.parent.contributionId+'/pay_credit_card',
      data: data,
      success: function(response){
        that.parent.loader.hide();

        if(response.payment_status == 'failed'){
          that.message.find('.message-text').html(response.message);
          that.message.slideDown('slow');

          $("#credit_card_submit").show();
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
    var number = $(e.currentTarget).val();
    this.$('#payment_card_flag').html(this.getCardFlag(number))
  },

  getCardFlag: function(number) {
    var flag = $.payment.cardType(number);
    return flag && flag.toUpperCase();
  }
}, Skull.Form));
