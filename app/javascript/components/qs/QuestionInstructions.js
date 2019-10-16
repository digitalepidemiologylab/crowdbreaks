import React from 'react'
import Modal from 'react-modal';
import Markdown from 'react-markdown';

export class QuestionInstructions extends React.Component {
  constructor(props) {
    super(props);

    Modal.setAppElement('#qs-root')
    this.state = {
      modalIsOpen: true,
      modalWidth: '0px'
    };
  }

  componentDidMount() {
    this.updateModalSize();
    window.addEventListener('resize', () => this.updateModalSize());
  }

  componentWillUnmount() {
    window.removeEventListener('resize', () => this.updateModalSize());
  }

  updateModalSize() {
    let modalWidth;
    const windowWidth = window.innerWidth;
    if (windowWidth > 768) {
      // desktop
      modalWidth = '50%'   // values denote the 'right' property of the content style
    } else if (windowWidth > 576) {
      // tablet
      modalWidth = '30%'
    } else {
      // mobile
      modalWidth = '5%'
    }
    this.setState({modalWidth: modalWidth});
  }

  onModalClose() {
    this.setState({
      modalIsOpen: false
    });
    this.props.toggleQuestionInstructions()
  }

  render() {
    const modalStyle = {
      content : {
        top                   : '50%',
        left                  : '50%',
        right                 : this.state.modalWidth,
        bottom                : 'auto',
        marginRight           : '-50%',
        transform             : 'translate(-50%, -50%)',
        maxWidth              : '500px',
        borderColor           : '#ced7de',
        padding               : '35px',
        paddingTop            : '45px'
      }
    };
    const markdownStyle = {textAlign: 'left'}

    return (
      <Modal
        isOpen={this.state.modalIsOpen}
        onRequestClose={() => this.onModalClose()}
        contentLabel="Instructions"
        style={modalStyle} >
        <div className="row mb-4">
          <div className="col-12">
            <h3 className="mb-4">{this.props.translations.title}</h3>
            <div style={markdownStyle}>
              <Markdown source={this.props.instructions} />
            </div>
          </div>
        </div>
        <div className="row mb-4">
          <div className="col-12 text-center">
            <button className="btn btn-primary btn-lg" onClick={() => this.onModalClose()}>{this.props.translations.ok}</button>
          </div>
        </div>
      </Modal>
    );

  }
}
