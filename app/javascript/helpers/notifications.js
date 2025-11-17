import { toast, Flip } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const defaults = {
  position: 'top-right',
  autoClose: 5000,
  hideProgressBar: true,
  closeOnClick: true,
  pauseOnHover: true,
  draggable: true,
  progress: undefined,
  transition: Flip,
};

export const success = (message, options = {}) => {
  toast.success(message, { ...defaults, ...options });
};

export const info = (message, options = {}) => {
  toast.info(message, { ...defaults, ...options });
};

export const warn = (message, options = {}) => {
  toast.warn(message, { ...defaults, ...options });
};

export const error = (message, options = {}) => {
  toast.error(message, { ...defaults, ...options });
};
