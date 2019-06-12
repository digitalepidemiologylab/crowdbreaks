import React from 'react'
import Modal from 'react-modal';

export class InstructionModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      modalIsOpen: props.openModal,
      modalWidth: '0px'
    };
  }

  componentWillMount() {
    Modal.setAppElement('#qs-root')
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
  }

  handleRequestCloseFunc() {
    // Navigate back to projects section
    window.location = this.props.projectsPath;
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

    return (
      <Modal
        isOpen={this.state.modalIsOpen}
        onRequestClose={() => this.handleRequestCloseFunc()}
        contentLabel="Instructions"
        style={modalStyle} >
        <div className="row mb-4">
          <div className="col-12">
            <h3 className="text-center mb-4">{this.props.translations.welcome}</h3>
            <p>
              {this.props.translations.header}
            </p>
            <p>
              {this.props.translations.agree_header}
            </p>
              <ul>
                <li>{this.props.translations.agree_header_1}</li>
                <li>{this.props.translations.agree_header_2}</li>
              </ul>
          </div>
        </div>
        <div className="row mb-4">
          <div className="col-12 text-center">
            <button className="btn btn-primary btn-lg" onClick={() => this.onModalClose()}>{this.props.translations.lets_go}</button>
          </div>
        </div>
        <div className="row">
          <div className="col-12">
            <button className="btn btn-link" onClick={() => this.handleRequestCloseFunc()}>{this.props.translations.go_back}</button>
          </div>
        </div>
      </Modal>
    );
  }
}
