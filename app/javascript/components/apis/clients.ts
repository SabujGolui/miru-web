import axios from "axios";

export interface IClient {
  id: number;
  name: string;
  email: string;
}

export const fetchClients = async (): Promise<IClient[]> => {
  try {
    const response = await axios("/internal_api/v1/clients");
    const parsedResponse: IClient[] = await response.data;
    return parsedResponse;
  } catch (err) {
    console.log(err);
  }
};