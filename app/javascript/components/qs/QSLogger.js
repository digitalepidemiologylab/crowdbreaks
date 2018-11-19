import moment from 'moment';

export class QSLogger {
  constructor(answerDelay) {
    this.log = this.getInitializedLog(answerDelay);
    this.timeLastAnswer = null;
  }

  getLog() {
    return this.log;
  }

  getTime() {
    return new Date().getTime();
  }

  logResult(questionId) {
    const now = this.getTime()
    this.log['results'].push({
      'submitTime': now,
      'timeSinceLastAnswer': now - this.timeLastAnswer,
      'questionId': questionId,
    });
  }

  logFinal() {
    const now = this.getTime()
    this.log['totalDurationQuestionSequence'] = now - this.log['timeMounted'];
    this.log['timeQuestionSequenceEnd'] = now;
  }

  logMturkSubmit() {
    const now = this.getTime();
    this.log['totalDurationUntilMturkSubmit'] = now - this.log['timeMounted'];
    this.log['timeMturkSubmit'] = now;
  }

  getInitializedLog(answerDelay) {
    return {
      'timeInitialized': this.getTime(),
      'userTimeInitialized': moment().format(),
      'results': [],
      'resets': [],
      'answerDelay': answerDelay,
    }
  }

  logMounted() {
    this.log['timeMounted'] = this.getTime();
    this.timeLastAnswer = this.getTime();
  }

  logReset(questionId) {
    this.log['resets'].push({
      'resetTime': this.getTime(),
      'resetAtQuestionId': questionId,
      'previousResultLog': this.log['results']
    });
    this.log['results'] = [];
  }
}
