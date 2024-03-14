import { useState, useEffect, useRef } from "react";
import FormattedDate from "./FormattedDate";
function Card({ element }) {
  const [isPlaying, setIsPlaying] = useState(false);
  const handlePlayPauseClick = () => {
    if (isPlaying) {
      // we need to pause here
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play();
      setIsPlaying(true);
    }
  };
  const audioRef = useRef(null);
  const [collapsed, setCollapsed] = useState(true);
  return (
    <li>
      <div className="card-container">
        <img
          onClick={() => setCollapsed(!collapsed)}
          src={element.image_url}
        ></img>
        <h3 id="obituary-name">{element.name}</h3>
        <p id="obituary-date">
          <FormattedDate date={element.born} /> -{" "}
          <FormattedDate date={element.death} />
        </p>
        <div className={`${collapsed ? "hidden" : ""}`}>
          <p id="obituary-text">{element.obituary}</p>
          <audio ref={audioRef}>
            <source src={element.audio_url} type="audio/mpeg" />
          </audio>
          <button onClick={handlePlayPauseClick}>
            {isPlaying ? "Pause" : "Play"}
          </button>
        </div>
      </div>
    </li>
  );
}

export default Card;
