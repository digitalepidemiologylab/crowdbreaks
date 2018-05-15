import React from 'react'
import PropTypes from 'prop-types';
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
    var modalWidth;
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
    var modalStyle = {
      content : {
        top                   : '50%',
        left                  : '50%',
        right                 : this.state.modalWidth,
        bottom                : 'auto',
        marginRight           : '-50%',
        transform             : 'translate(-50%, -50%)',
        maxWidth: '550px',
        borderColor: '#ced7de'
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
            <h3 className="text-center mb-4">Welcome!</h3>
            <p>
              In this project we will ask you a series of questions about a tweet in order to better understand vaccine sentiments. Please answer these questions as best as you can from the tweet text alone (without following links). Your help is much appreciated!
            </p>
            <p>
              By continuing you agree to the following:
            </p>
              <ul>
                <li>You are at least 18 years old.</li>
                <li>You understand that this is a research project and the answers you provide will be used for research purposes only.</li>
              </ul>
          </div>
        </div>
        <div className="row mb-4">
          <div className="col-12 text-center">
            <button className="btn btn-primary btn-lg" onClick={() => this.onModalClose()}>Let's go!</button>
          </div>
        </div>
        <div className="row">
          <div className="col-12">
            <button className="btn btn-link" onClick={() => this.handleRequestCloseFunc()}>Go back</button>
          </div>
        </div>
      </Modal>
    );

  }
};
