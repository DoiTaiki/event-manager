import React, { useState, useRef } from 'react';
import PropTypes from 'prop-types';
import { Link, NavLink } from 'react-router-dom';

const EventList = ({ events }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const searchInput = useRef(null);

  const updateSearchTerm = () => {
    setSearchTerm(searchInput.current.value);
  };

  const matchSearchTerm = (obj) => {
    const {
      id,
      published,
      created_at, // eslint-disable-line camelcase
      updated_at, // eslint-disable-line camelcase
      ...rest
    } = obj;
    return Object.values(rest).some(
      (value) => typeof value === 'string' && value.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1,
    );
  };

  const renderEvents = (eventArray) => {
    const filteredEvents = [...eventArray].filter((el) => matchSearchTerm(el));
    // Guarded date sort: handles invalid or missing dates to prevent NaN and unpredictable order
    // - Valid dates are sorted in descending order (newest first)
    // - Invalid/missing dates are placed at the end to ensure stable, predictable sorting
    const sortedEvents = [...filteredEvents].sort((a, b) => {
      const dateA = a.event_date ? new Date(a.event_date) : null;
      const dateB = b.event_date ? new Date(b.event_date) : null;

      // Validate dates to prevent NaN from invalid date strings
      const isValidDateA = dateA && !Number.isNaN(dateA.getTime());
      const isValidDateB = dateB && !Number.isNaN(dateB.getTime());

      // Handle null/undefined/invalid dates: place them at the end
      // This prevents NaN comparisons and ensures predictable sort order
      if (!isValidDateA && !isValidDateB) return 0;
      if (!isValidDateA) return 1; // a goes after b
      if (!isValidDateB) return -1; // b goes after a

      // Both dates are valid, compare normally (newest first)
      return dateB - dateA;
    });

    return sortedEvents
      .map((event) => (
        <li key={event.id}>
          <NavLink to={`/events/${event.id}`}>
            {event.event_date}
            {' - '}
            {event.event_type}
          </NavLink>
        </li>
      ));
  };

  return (
    <section className="eventList">
      <h2>
        Events
        <Link to="/events/new">New Event</Link>
      </h2>

      <input
        className="search"
        placeholder="Search"
        type="text"
        ref={searchInput}
        onKeyUp={updateSearchTerm}
      />

      <ul>{renderEvents(events)}</ul>
    </section>
  );
};

EventList.propTypes = {
  events: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number,
    event_type: PropTypes.string,
    event_date: PropTypes.string,
    title: PropTypes.string,
    speaker: PropTypes.string,
    host: PropTypes.string,
    published: PropTypes.bool,
  })).isRequired,
};

export default EventList;
