import React from "react";

import dayjs from "dayjs";
import { lineTotalCalc, minToHHMM } from "helpers";
import InfiniteScroll from "react-infinite-scroll-component";

import NewLineItemTableHeader from "./Header";

import { getMaxIdx } from "../utils";

const NewLineItemTable = ({
  setShowItemInputs,
  addNew, setAddNew,
  lineItems, setLineItems,
  loadMoreItems,
  totalLineItems,
  pageNumber, setPageNumber,
  selectedLineItems, setSelectedLineItems,
  manualEntryArr, setManualEntryArr,
  setMultiLineItemModal,
  setAddManualLineItem
}) => {
  const hasMoreItems = lineItems.length != totalLineItems;

  const selectRowId = (items) => {
    const option = { ...items, lineTotal: lineTotalCalc(items.quantity, items.rate) };
    setAddNew(false);
    setSelectedLineItems([...selectedLineItems, option]);
    setLineItems([]);
    setPageNumber(1);
  };

  const addManualEntryItem = () => {
    setShowItemInputs(true);
    setAddNew(!addNew);
    setAddManualLineItem(true);
    setManualEntryArr([...manualEntryArr, { idx: getMaxIdx(manualEntryArr) + 1 }]);
  };

  return (
    <div>
      <NewLineItemTableHeader setShowMultilineModal={setMultiLineItemModal} addManualEntryItem={addManualEntryItem} />
      <div className="overflow-scroll mt-4 relative">
        <InfiniteScroll
          dataLength={pageNumber * 10}
          next={loadMoreItems}
          hasMore={hasMoreItems}
          loader={
            <div className="text-center py-2">
              <h4>Loading...</h4>
            </div>
          }
          height={250}
          endMessage={
            <p className="text-center py-2">
              <b>End of the list</b>
            </p>
          }
        >
          {lineItems.map((item, index) => {
            const hoursLogged = minToHHMM(item.quantity);
            const date = dayjs(item.date).format("DD.MM.YYYY");
            return (
              <div key={index} onClick={() => selectRowId(item)} className="py-2 px-3 flex justify-between cursor-pointer hover:bg-miru-gray-100" data-cy="entries-list">
                <span className="font-medium w-1/5 text-sm text-miru-dark-purple-1000 text-left">
                  {item.first_name} {item.last_name}
                </span>
                <span className="font-medium w-3/5 text-xs text-miru-dark-purple-600 text-left whitespace-normal">
                  {item.description}
                </span>
                <span className="font-medium text-xs text-miru-dark-purple-1000 text-right">
                  {date}
                </span>
                <span className="font-medium w-1/12 text-xs text-miru-dark-purple-1000 text-right">
                  {hoursLogged}
                </span>
              </div>
            );
          })
          }
        </InfiniteScroll>
      </div>
    </div>
  );
};

export default NewLineItemTable;
