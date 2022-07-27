public with sharing class AnswersAndQuestionsScreenController {

    @AuraEnabled
    public static String getAccount (String eventId) {
        Event event = [
            SELECT Id, EventType__c, Account__c FROM Event WHERE Id =: eventId
        ];

        return event.Account__c;
    }

    @AuraEnabled
    public static String getEventRelated (String eventId) {
        Event event = [
            SELECT Id, EventType__c, Account__c, EventRelated__c FROM Event WHERE Id =: eventId
        ];

        return event.EventRelated__c;
    }

    @AuraEnabled
    public static List<QuestionObject> getQuestions (String eventId) {

        Event event = [
            SELECT Id, EventType__c, EventRelated__c FROM Event WHERE Id =: eventId
        ];

        String eventRelatedId = event.EventRelated__c;

        Boolean hasAnswers = false;

        List<Answer__c> checkAnswers = [
            SELECT Id, EventRelated__c, Question__c, Answer__c, AnswerBoolean__c, AnswerDate__c FROM Answer__c WHERE EventRelated__c =: eventRelatedId
        ];

        System.debug(checkAnswers);

        if (!checkAnswers.isEmpty()) {
            hasAnswers = true;
        }

        Map<Id, Answer__c> mapIdToAnswer = new Map<Id, Answer__c>();

        if (hasAnswers) {
            for (Answer__c answer : checkAnswers) {
                if (!mapIdToAnswer.containsKey(answer.Question__c)) {
                    mapIdToAnswer.put(answer.Question__c, answer);
                }
            }
        }

        String visitType;

        visitType = event.EventType__c;

        List<QuestionXEventType__c> questionXEventTypeList = [
            SELECT Id, Pergunta__c, EventType__c FROM QuestionXEventType__c WHERE EventType__c =: visitType
        ];

        List<String> questionIdList = new List<String>();

        for (QuestionXEventType__c questionEvent : questionXEventTypeList) {
            questionIdList.add(questionEvent.Pergunta__c);
        }

        List<Question__c> questions = [
            SELECT Id, QuestionDescription__c, Required__c, QuestionType__c, PicklistValues__c FROM Question__c WHERE Id IN: questionIdList
        ];

        List<QuestionObject> questionObjectList = new List<QuestionObject>();

        for (Question__c question : questions) {
            if (hasAnswers) {
                questionObjectList.add(new QuestionObject(question, mapIdToAnswer.get(question.Id)));
            } else {
                questionObjectList.add(new QuestionObject(question));
            }
        }

        return questionObjectList;
    }

    @AuraEnabled(cacheable=false)
    public static List<AnswerObject> saveAnswers (String answers) {

        System.debug(answers);

        List<AnswerObject> answerObjectList = (List<AnswerObject>)JSON.deserialize(answers, List<AnswerObject>.class);

        System.debug(answerObjectList);

        List<Answer__c> answerList = new List<Answer__c>();

        for(AnswerObject answer : answerObjectList) {
            answerList.add(convertToAnswerObject(answer));
        }

        System.debug(answerList.size());
        System.debug(answerList);

        upsert answerList;

        return answerObjectList;
    }

    @AuraEnabled
    public static Answer__c convertToAnswerObject(AnswerObject answerObject) {
        Answer__c answer = new Answer__c (
            Id = answerObject.id,
            Account__c = answerObject.account,
            EventRelated__c = answerObject.eventRelated,
            Question__c = answerObject.question,
            Answer__c = answerObject.answer,
            AnswerBoolean__c = answerObject.answerBoolean,
            AnswerDate__c = answerObject.answerDate
        );

        return answer;
    }

    public class QuestionObject {
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String QuestionDescription {get;set;}
        @AuraEnabled public Boolean Required {get;set;}
        @AuraEnabled public String QuestionType {get;set;}
        @AuraEnabled public Boolean EnableCheckBox {get;set;}
        @AuraEnabled public Boolean EnableTextArea {get;set;}
        @AuraEnabled public Boolean EnableDataField {get;set;}
        @AuraEnabled public Boolean EnablePickList {get;set;}
        @AuraEnabled public String PicklistValues {get;set;}
        @AuraEnabled public Date AnswerDate {get;set;}
        @AuraEnabled public String Answer {get;set;}
        @AuraEnabled public Boolean AnswerBoolean {get;set;}
        @AuraEnabled public String AnswerId {get;set;}

        public QuestionObject(Question__c questions) {
            this.Id                     = questions.Id;
            this.QuestionDescription    = questions.QuestionDescription__c;
            this.Required               = questions.Required__c;
            this.PicklistValues         = questions.PicklistValues__c;
            this.QuestionType           = questions.QuestionType__c;
            this.EnableCheckBox         = questions.QuestionType__c == 'Caixa de Seleção' ? true : false;
            this.EnableTextArea         = questions.QuestionType__c == 'Texto para livre preenchimento' ? true : false;
            this.EnableDataField        = questions.QuestionType__c == 'Data' ? true : false;
            this.EnablePickList         = questions.QuestionType__c == 'Valores Predefinidos' ? true : false;
            this.AnswerDate             = null;
            this.Answer                 = null;
            this.AnswerBoolean          = false;
            this.AnswerId               = null;
        }

        public QuestionObject(Question__c questions, Answer__c answer) {
            this.Id                     = questions.Id;
            this.QuestionDescription    = questions.QuestionDescription__c;
            this.Required               = questions.Required__c;
            this.PicklistValues         = questions.PicklistValues__c;
            this.QuestionType           = questions.QuestionType__c;
            this.EnableCheckBox         = questions.QuestionType__c == 'Caixa de Seleção' ? true : false;
            if (this.EnableCheckBox) {
                this.AnswerBoolean = answer.AnswerBoolean__c ? answer.AnswerBoolean__c : false;
            }
            this.EnableTextArea         = questions.QuestionType__c == 'Texto para livre preenchimento' ? true : false;
            if (this.EnableTextArea) {
                this.Answer = answer.Answer__c;
                this.AnswerBoolean = false;
            }
            this.EnableDataField        = questions.QuestionType__c == 'Data' ? true : false;
            if (this.EnableDataField) {
                this.AnswerDate = answer.AnswerDate__c;
                this.AnswerBoolean = false;
            }
            this.EnablePickList         = questions.QuestionType__c == 'Valores Predefinidos' ? true : false;
            if (this.EnablePickList) {
                this.Answer = answer.Answer__c;
                this.AnswerBoolean = false;
            }
            this.AnswerId = answer.Id;
        }
    }

    public class AnswerObject {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String account {get;set;}
        @AuraEnabled public String question {get;set;}
        @AuraEnabled public String eventRelated {get;set;}
        @AuraEnabled public String answer {get;set;}
        @AuraEnabled public Boolean answerBoolean {get;set;}
        @AuraEnabled public Date answerDate {get;set;}

        //public AnswerObject (String answerObj) {
        //    this.id = answerObj.id;
        //    this.account = answerObj.account;
        //    this.question = answerObj.question;
        //    this.eventRelated = answerObj.eventRelated;
        //    this.answer = answerObj.answer;
        //    this.answerBoolean = answerObj.answerBoolean;
        //    this.answerDate = answerObj.answerDate;
        //}

    }
}
