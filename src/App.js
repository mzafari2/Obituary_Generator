import { useState, useEffect, useRef } from "react";
import Card from "./Card";

function App() {
  // this creates a null reference which needs to be hooked up to an HTML element
  const [obituaries, setObituaries] = useState([]);
  const currentDate = () => {
    const newDate = new Date();
    return new Date(newDate.getTime() - newDate.getTimezoneOffset() * 60000)
      .toJSON()
      .substring(0, 19);
  };
  const [deceasedName, setDeceasedName] = useState("");
  const [bornDate, setBornDate] = useState("");
  const [deathDate, setDeathDate] = useState(currentDate(new Date()));
  const [file, setFile] = useState(null);

  //display obituray text
  const [showObituary, setShowObituary] = useState(
    new Array(obituaries.length).fill(false)
  );
  useEffect(() => {
    const getData = async () => {
      // default HTTP method is GET
      const result = await fetch(
        `https://xps5kni5xoawdioq6jpcz7r5ei0vpigg.lambda-url.ca-central-1.on.aws/`
      );
      const data = await result.json();
      console.log(data);
      setObituaries(data);
    };
    getData();
  }, []);

  const [submitting, setSubmitting] = useState(false);

  const onSubmitForm = async (e) => {
    e.preventDefault();
    setSubmitting(true);

    const data = new FormData();
    data.append("file", file);
    data.append("name", deceasedName);
    data.append("born", bornDate);
    data.append("death", deathDate);

    const promise = await fetch(
      `https://iprtcji35xugmht52qxul42ady0acnoz.lambda-url.ca-central-1.on.aws`,
      {
        method: "POST",
        body: data,
      }
    );

    const result = await promise.json();
    console.log(result);
    setSubmitting(false);

    if (promise.ok) {
      setObituaries([result, ...obituaries]);
      closeNewOrbituary();
      //setCollapsed(true);
    } else {
      // show error message
    }
  };
  const onFileChange = (e) => {
    console.log(e.target.files);
    setFile(e.target.files[0]);
  };
  const [showMenu, setShowMenu] = useState(false);
  const addNewOrbituary = () => {
    setShowMenu(true);
  };

  const closeNewOrbituary = () => {
    setShowMenu(false);
  };

  return (
    <div className="container">
      {!showMenu && (
        <>
          <div className="header">
            <h1 id="title-holder">The Last Show</h1>
            <button id="menu-left" onClick={addNewOrbituary}>
              + New Obituary
            </button>
          </div>

          <div className="display-obituaries">
            {obituaries.length > 0 ? (
              <ul>
                {obituaries.map((element, i) => (
                  <Card element={element} />
                ))}
              </ul>
            ) : (
              <p id="initialState">No orbituary yet</p>
            )}
          </div>
        </>
      )}
      {showMenu && (
        <div className="new-orbituary-page">
          <p id="head-text">Create A New Obituary</p>
          <img
            src="https://i.pinimg.com/564x/2e/20/eb/2e20ebb802a037189bef8e3fa2ff2082.jpg"
            alt="rose"
          ></img>
          <div id="info">
            <form onSubmit={(e) => onSubmitForm(e)}>
              <input
                type="file"
                requried
                accept="image/*"
                onChange={(e) => onFileChange(e)}
              />
              <div>
                <input
                  id="deceasedName"
                  type="text"
                  value={deceasedName}
                  onChange={(e) => setDeceasedName(e.target.value)}
                  placeholder="Name of the deceased"
                  required
                />
              </div>
              <div id="dates">
                <p>Born:</p>
                <input
                  value={bornDate}
                  onChange={(e) => setBornDate(e.target.value)}
                  type="datetime-local"
                ></input>
                <p>Died:</p>
                <input
                  type="datetime-local"
                  value={deathDate ? deathDate : currentDate()}
                  onChange={(event) => setDeathDate(event.target.value)}
                ></input>
              </div>
              <input
                id="writeObituary"
                type="submit"
                value={submitting ? "Please wait..." : "Write Obituary"}
                disabled={submitting}
              />
            </form>
          </div>
          <button id="exit-button" onClick={closeNewOrbituary}>
            Exit
          </button>
        </div>
      )}
    </div>
  );
}

export default App;
