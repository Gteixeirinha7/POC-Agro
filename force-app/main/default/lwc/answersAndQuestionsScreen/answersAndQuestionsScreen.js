import { LightningElement, api, track, wire } from 'lwc';
import getQuestions from '@salesforce/apex/AnswersAndQuestionsScreenController.getQuestions';
import saveAnswers from '@salesforce/apex/AnswersAndQuestionsScreenController.saveAnswers';
import getAccount from '@salesforce/apex/AnswersAndQuestionsScreenController.getAccount';
import getEventRelated from '@salesforce/apex/AnswersAndQuestionsScreenController.getEventRelated';
import { NavigationMixin } from 'lightning/navigation';

export default class AnswersAndQuestionsScreen extends NavigationMixin(LightningElement) {
    @api visitType = false;
    @api recordId;
    @api textValue;
    @api accountId;
    @api testValue;
    @api eventRelatedId;
    @api questionList = [];
    @api answerObj = [];
    @api showAnswersAndQuestions = false;

    async connectedCallback() {
        await this.getQuestions();
        await this.getAccountId();
        await this.getEventRelatedId();
        await this.createAnswerObject();
        this.showAnswersAndQuestions = true;
    }

    confirmAnswers(event) {
        var value = event.target.value;
        var questionId = event.currentTarget.dataset.questionId;
        var question = this.questionList.find(question => question.Id == questionId);
        this.answerObj.filter(answer => answer.question == questionId).forEach(answer => {
            if (question.EnableTextArea || question.EnablePickList) {
                answer.answer = value;
                answer.answerDate = null;
                answer.answerBoolean = false;
            }
            if (question.EnableDataField) {
                answer.answerDate = value;
                answer.answer = "";
                answer.answerBoolean = false;
            }
            if (question.EnableCheckBox) {
                answer.answerBoolean = value;
                answer.answer = "";
                answer.answerDate = null;
            }
        });
    }

    confirmAnswersCheckBox(event) {
        var value = event.target.checked;
        var questionId = event.currentTarget.dataset.questionId;
        var question = this.questionList.find(question => question.Id == questionId);
        this.answerObj.filter(answer => answer.question == questionId).forEach(answer => {
            if (question.EnableTextArea || question.EnablePickList) {
                answer.answer = value;
                answer.answerDate = null;
                answer.answerBoolean = false;
            }
            if (question.EnableDataField) {
                answer.answerDate = value;
                answer.answer = "";
                answer.answerBoolean = false;
            }
            if (question.EnableCheckBox) {
                answer.answerBoolean = value;
                answer.answer = "";
                answer.answerDate = null;
            }
        });
    }

    async saveAnswer() {
        var blankAnswer = false;
        this.answerObj.forEach(answer => {
            if (answer.required) {
                if (answer.enableTextArea || answer.enablePickList) {
                    if (answer.answer == null || answer.answer == undefined || answer.answer == "") {
                        alert("Um campo obrigatório não foi preenchido");
                        blankAnswer = true;
                        return;
                    }
                }
                if (answer.enableDataField) {
                    if (answer.answerDate == null || answer.answerDate == undefined) {
                        alert("Um campo obrigatório não foi preenchido");
                        blankAnswer = true;
                        return;
                    }
                }
                if (answer.enableCheckBox) {
                    if (answer.answerBoolean == null || answer.answerBoolean == undefined) {
                        alert("Um campo obrigatório não foi preenchido");
                        blankAnswer = true;
                        return;
                    }
                }
            }
        });
        if (!blankAnswer) {
            await saveAnswers({ answers: JSON.stringify(this.answerObj) }).then(data => {
                if (data) {
                    this.navigateToView();
                } else {
                    this.navigateToView();
                }
            }).catch(error => {});
            this.dispatchEvent(new CustomEvent('close'));
        }
    }

    async getQuestions() {
        await getQuestions({ eventId: this.recordId }).then(data => {
            if (data) {
                if (data.length > 0) {
                    this.questionList = data;
                }
            }
        }).catch(error => {});
    }

    async getEventRelatedId() {
        await getEventRelated({ eventId: this.recordId }).then(data => {
            if (data) {
                this.eventRelatedId = data;
            }
        }).catch(error => {});
    }

    async getAccountId() {
        await getAccount({ eventId: this.recordId }).then(data => {
            if (data) {
                this.accountId = data;
            }
        }).catch(error => {});
    }

    navigateToView() {
        this.showAnswersAndQuestions = false;
        this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId: this.recordId, objectApiName: 'Event', actionName: 'view' } });
    }

    handleInputChange(event) {
        this.textValue = event.detail.value;
    }

    createAnswerObject() {
        this.questionList.forEach(question => {
            var answerObject = {
                "id": question.AnswerId,
                "required": question.Required,
                "account": this.accountId,
                "eventRelated": this.eventRelatedId,
                "question": question.Id,
                "questionDescription": question.QuestionDescription,
                "enableCheckBox": question.EnableCheckBox,
                "enableTextArea": question.EnableTextArea,
                "enableDataField": question.EnableDataField,
                "enablePickList": question.EnablePickList,
                "answer": question.Answer,
                "answerBoolean": question.AnswerBoolean,
                "answerDate": question.AnswerDate,
                "picklistValue": this.makeOptionList(question.PicklistValues)
            }

            this.answerObj.push(answerObject);
        });
    }

    makeOptionList(list) {
        if (list != undefined || list != null) {
            var aux = list.split(',');
            var returnList = [];
            aux.forEach(options => {
                var auxOjb = {
                    "value": options,
                    "label": options
                }
                returnList.push(auxOjb);
            })

            return returnList
        } else {
            return null
        }
    }
}