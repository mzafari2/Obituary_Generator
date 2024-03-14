const options = {
  year: "numeric",
  month: "long",
  day: "numeric",
};

const formatDate = (when) => {
  const formatted = new Date(when).toLocaleString("en-US", options);
  if (formatted === "Invalid Date") {
    return "";
  }

  return formatted;
};

function FormattedDate({ date }) {
  return formatDate(date);
}

export default FormattedDate;
