import moment from 'moment';

export class QSLogger {
  constructor(answerDelay) {
    this.timeLastAnswer = null;
    this.answerDelay = answerDelay;
    this.timeMounted = null;
    this.initializeLog();
  }

  getLog() {
    return this.log;
  }

  getTime() {
    return new Date().getTime();
  }

  reset() {
    this.initializeLog();
  }

  logResult(questionId) {
    const now = this.getTime()
    this.log['results'].push({
      'submitTime': now,
      'timeSinceLastAnswer': now - this.timeLastAnswer,
      'questionId': questionId,
    });
    this.timeLastAnswer = now;
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

  initializeLog(answerDelay) {
    this.log = {
      'timeInitialized': this.getTime(),
      'userTimeInitialized': moment().format(),
      'results': [],
      'resets': [],
      'answerDelay': answerDelay,
      'timeMounted': this.timeMounted,
    }
  }

  logMounted() {
    const now = this.getTime()
    this.log['timeMounted'] = now;
    this.timeLastAnswer = now;
    this.timeMounted = now;
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
