import React from 'react';
import PropTypes from 'prop-types';

const EventList = ({ events }) => {
  const renderEvents = (eventArray) => {
    // Guarded date sort: handles invalid or missing dates to prevent NaN and unpredictable order
    // - Valid dates are sorted in descending order (newest first)
    // - Invalid/missing dates are placed at the end to ensure stable, predictable sorting
    const sortedEvents = [...eventArray].sort((a, b) => {
      const dateA = a.event_date ? new Date(a.event_date) : null;
      const dateB = b.event_date ? new Date(b.event_date) : null;

      // Validate dates to prevent NaN from invalid date strings
      const isValidDateA = dateA && !isNaN(dateA.getTime());
      const isValidDateB = dateB && !isNaN(dateB.getTime());

      // Handle null/undefined/invalid dates: place them at the end
      // This prevents NaN comparisons and ensures predictable sort order
      if (!isValidDateA && !isValidDateB) return 0;
      if (!isValidDateA) return 1; // a goes after b
      if (!isValidDateB) return -1; // b goes after a

      // Both dates are valid, compare normally (newest first)
      return dateB - dateA;
    });

    return sortedEvents.map((event) => (
      <li key={event.id}>
        {event.event_date || 'No date'}
        {' - '}
        {event.event_type}
      </li>
    ));
  };

  return (
    <section>
      <h2>Events</h2>
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
