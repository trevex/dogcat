// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
import type { NextApiRequest, NextApiResponse } from 'next'
import { Score } from "../../models";

type Data = {
    name: string
}

export default async function handler(
    req: NextApiRequest,
    res: NextApiResponse<Data>
) {
    const s = await Score.create({
        username: 'janedoe',
        datetime: new Date(1980, 6, 20),
        score: 100,
    });
    res.status(200).json(s)
}
